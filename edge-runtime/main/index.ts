// Main service entry point for Edge Runtime
// Handles routing, JWT validation, CORS, and request preprocessing

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// JWT validation configuration
const JWT_SECRET = Deno.env.get("JWT_SECRET") || "";
const ANON_KEY = Deno.env.get("ANON_KEY") || "";
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY") || "";

// CORS configuration
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS, PUT, DELETE",
};

// JWT validation function
async function validateJWT(token: string): Promise<boolean> {
  if (!JWT_SECRET || !token) return false;

  try {
    // Allow anon and service role keys
    if (token === ANON_KEY || token === SERVICE_ROLE_KEY) {
      return true;
    }

    // Import crypto for JWT verification
    const encoder = new TextEncoder();
    const keyData = encoder.encode(JWT_SECRET);
    const key = await crypto.subtle.importKey(
      "raw",
      keyData,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["verify"]
    );

    // Parse JWT (simplified - in production use a JWT library)
    const parts = token.split(".");
    if (parts.length !== 3) return false;

    // Verify signature
    const message = encoder.encode(`${parts[0]}.${parts[1]}`);
    const signature = Uint8Array.from(
      atob(parts[2].replace(/-/g, "+").replace(/_/g, "/")),
      (c) => c.charCodeAt(0)
    );

    const isValid = await crypto.subtle.verify("HMAC", key, signature, message);

    if (isValid) {
      // Check expiration
      const payload = JSON.parse(atob(parts[1]));
      const now = Math.floor(Date.now() / 1000);
      return payload.exp ? payload.exp > now : true;
    }

    return false;
  } catch (error) {
    console.error("JWT validation error:", error);
    return false;
  }
}

// Extract function name from URL path
function extractFunctionName(url: string): string | null {
  const urlObj = new URL(url);
  const pathParts = urlObj.pathname.split("/").filter((p) => p);

  // Support both /function-name and /functions/v1/function-name patterns
  if (pathParts.length >= 1) {
    return pathParts[pathParts.length - 1];
  }

  return null;
}

// Main request handler
Deno.serve(async (req: Request) => {
  const url = new URL(req.url);

  // Health check endpoint
  if (url.pathname === "/health") {
    return new Response(
      JSON.stringify({ status: "healthy", timestamp: new Date().toISOString() }),
      {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  // Extract JWT from headers
  const authHeader = req.headers.get("authorization");
  const apiKey = req.headers.get("apikey");
  const token = authHeader?.replace("Bearer ", "") || apiKey;

  // Validate JWT if required
  const requireAuth = Deno.env.get("REQUIRE_AUTH") !== "false";
  if (requireAuth && !token) {
    return new Response(
      JSON.stringify({ error: "Missing authentication token" }),
      {
        status: 401,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }

  if (requireAuth && token) {
    const isValid = await validateJWT(token);
    if (!isValid) {
      return new Response(
        JSON.stringify({ error: "Invalid authentication token" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }
  }

  // Extract function name from URL
  const functionName = extractFunctionName(req.url);
  if (!functionName) {
    return new Response(
      JSON.stringify({ error: "Function name not specified in URL path" }),
      {
        status: 400,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }

  // Route to the appropriate Edge Function
  try {
    // Import and execute the Edge Function
    const functionPath = `/usr/services/functions/${functionName}/index.ts`;

    // Check if function exists
    try {
      await Deno.stat(functionPath);
    } catch {
      return new Response(
        JSON.stringify({
          error: `Function '${functionName}' not found`,
          available_functions: await listAvailableFunctions(),
        }),
        {
          status: 404,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }

    // Import and execute the function
    const functionModule = await import(functionPath);

    // Create modified request with additional context
    const modifiedReq = new Request(req.url, {
      method: req.method,
      headers: req.headers,
      body: req.body,
    });

    // Execute the Edge Function
    const response = await functionModule.default(modifiedReq);

    // Add CORS headers to response
    const headers = new Headers(response.headers);
    Object.entries(corsHeaders).forEach(([key, value]) => {
      if (!headers.has(key)) {
        headers.set(key, value);
      }
    });

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  } catch (error) {
    console.error(`Error executing function '${functionName}':`, error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
});

// Helper function to list available functions
async function listAvailableFunctions(): Promise<string[]> {
  try {
    const functions: string[] = [];
    const functionsDir = "/usr/services/functions";

    for await (const entry of Deno.readDir(functionsDir)) {
      if (entry.isDirectory) {
        // Check if index.ts exists
        try {
          await Deno.stat(`${functionsDir}/${entry.name}/index.ts`);
          functions.push(entry.name);
        } catch {
          // Skip if no index.ts
        }
      }
    }

    return functions;
  } catch {
    return [];
  }
}

console.log("🚀 Edge Runtime main service started");
console.log("📍 Health check: /health");
console.log("📍 Functions: /{function-name}");
console.log(`🔒 Auth required: ${Deno.env.get("REQUIRE_AUTH") !== "false"}`);
