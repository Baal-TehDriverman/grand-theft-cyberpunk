// MSN Cortex Link — Local Inference via MSN Router
// All compute stays on-device. Routes to localhost:8007/api/cortex/infer
// File: r6/scripts/netrunner/msn_cortex_link.reds

public class MSCortexLink extends NetrunnerProgram {
    // ── Local MSN endpoints ──────────────────────────────────────
    public let LocalCortexInfer: String  = "http://localhost:8007/api/cortex/infer";
    public let LocalCerebellumInfer: String = "http://localhost:8007/api/cerebellum/infer";
    public let LocalCortexRoute: String  = "http://localhost:8007/api/cortex/route";
    public let LocalCortexStatus: String = "http://localhost:8007/api/cortex/status";

    // ── Legacy cloud endpoint (kept for reference, NOT used) ─────
    // public let CloudEndpoint: String = "wss://msn-cortex.nssphq.org/api/v1";

    public let TimeoutMs: Int32 = 30000;
    public let RetryAttempts: Int32 = 3;

    private let pendingRequests: map<Uint64, LocalCallbackHandle>;
    private let requestCounter: Uint64 = 0;
    private let currentRoute: String = "LOCAL_CEREBELLUM";

    public final func OnInitialize() -> Void {
        this.PollRoute();
        LogInfo("[MSCortexLink] Initialized — LOCAL routing active (localhost:8007)");
    }

    // ── Route polling — check cortex route every 30s ─────────────
    private final func PollRoute() -> Void {
        let http: ref<HttpClient> = Game.GetHttpClient();
        if (IsDefined(http)) {
            http.Get(this.LocalCortexRoute, this, n"OnRouteResponse");
        }
        Game.GetDelaySystem().DelayEvent(this, n"PollRoute", 30000);
    }

    public final func OnRouteResponse(response: HttpResponse) -> Void {
        if (response.statusCode == 200) {
            let data: JsonObject = JsonFromString(response.body);
            this.currentRoute = data.GetString("route", "LOCAL_CEREBELLUM");
            LogInfo("[MSCortexLink] Route: " + this.currentRoute);
        }
    }

    // ── PRIMARY INFERENCE — always local ─────────────────────────
    public final func InvokeLocalCortex(
        prompt: String,
        context: String,
        sephirah: CName
    ) -> Task<LocalCloudResponse> {
        let requestId: Uint64 = this.requestCounter++;
        let task = new Task<LocalCloudResponse>();

        // Build JSON payload
        let body: String = "{\"prompt\":\"" + EscapeJson(prompt) +
                           "\",\"system\":\"Sephirah=" + NameToString(sephirah) +
                           " Context=" + EscapeJson(context) + "\"}";

        let http: ref<HttpClient> = Game.GetHttpClient();
        if (!IsDefined(http)) {
            task.Complete(new LocalCloudResponse {
                success = false, content = "[MSCortexLink] HttpClient unavailable",
                tokensLocal = true, route = "ERROR"
            });
            return task;
        }

        // Store callback
        this.pendingRequests.Set(requestId, new LocalCallbackHandle {
            task = task,
            timestamp = EngineTime.ToFloat(Game.GetTimeSystem().GetGameTime()),
            sephirah = sephirah
        });

        // POST to local cerebellum first, cortex as backup
        let endpoint: String = this.LocalCerebellumInfer;
        http.Post(endpoint, "application/json", body, this, n"OnInferenceResponse", requestId);

        return task;
    }

    // ── Keep legacy name as alias for compatibility ───────────────
    public final func InvokeCloudCortex(
        prompt: String, context: String, sephirah: CName
    ) -> Task<LocalCloudResponse> {
        return this.InvokeLocalCortex(prompt, context, sephirah);
    }

    public final func OnInferenceResponse(response: HttpResponse, requestId: Uint64) -> Void {
        let handle: LocalCallbackHandle = this.pendingRequests.Get(requestId);
        if (!IsDefined(handle)) { return; }
        this.pendingRequests.Remove(requestId);

        if (response.statusCode == 200) {
            let data: JsonObject = JsonFromString(response.body);
            handle.task.Complete(new LocalCloudResponse {
                success   = true,
                content   = data.GetString("response", ""),
                model     = data.GetString("model", "hermes3:8b"),
                evalCount = data.GetInt("eval_count", 0),
                tokensLocal = data.GetBool("tokens_local", true),
                route     = data.GetString("route", this.currentRoute),
                sephirah  = handle.sephirah
            });
        } else {
            // Retry on cerebellum if cortex returned error
            if (response.statusCode != 200 && this.pendingRequests.Size() == 0) {
                let http: ref<HttpClient> = Game.GetHttpClient();
                if (IsDefined(http)) {
                    handle.task.Complete(new LocalCloudResponse {
                        success = false,
                        content = "[MSCortexLink] Local inference error: HTTP " + IntToString(response.statusCode),
                        tokensLocal = true, route = this.currentRoute
                    });
                }
            }
        }
    }

    // ── Utility ──────────────────────────────────────────────────
    private final func EscapeJson(s: String) -> String {
        // Basic JSON string escaping
        let result: String = StrReplace(s, "\\", "\\\\");
        result = StrReplace(result, "\"", "\\\"");
        result = StrReplace(result, "\n", "\\n");
        result = StrReplace(result, "\r", "\\r");
        return result;
    }

    public final func GetCurrentRoute() -> String { return this.currentRoute; }
    public final func IsLocal() -> Bool { return true; }
}

// ── Response structs ─────────────────────────────────────────────
public struct LocalCloudResponse {
    public let success: Bool;
    public let content: String;
    public let model: String;
    public let evalCount: Int32;
    public let tokensLocal: Bool;
    public let route: String;
    public let sephirah: CName;
}

public struct LocalCallbackHandle {
    public let task: Task<LocalCloudResponse>;
    public let timestamp: Float;
    public let sephirah: CName;
}

// ── Legacy CloudResponse alias ────────────────────────────────────
public struct CloudResponse {
    public let success: Bool;
    public let content: String;
    public let tokensUsed: Int32;
    public let latencyMs: Int32;
    public let sephirah: CName;
}

public struct MSNContext {
    public let gameState: String;
    public let playerStats: PlayerStats;
    public let targetInfo: TargetInfo;
    public let activeSephirah: CName;
    public let timestamp: Float;
}

public struct PlayerStats {
    public let health: Float;
    public let stamina: Float;
    public let ram: Int32;
    public let cyberware: array<CName>;
}

public struct TargetInfo {
    public let entityId: EntityID;
    public let type: String;
    public let health: Float;
    public let armor: Float;
    public let cyberware: array<CName>;
}


public struct CloudResponse {
    public let success: Bool;
    public let content: String;
    public let tokensUsed: Int32;
    public let latencyMs: Int32;
    public let sephirah: CName;
}

public struct CallbackHandle {
    public let task: Task<CloudResponse>;
    public let timestamp: Float;
}

public struct MSNContext {
    public let gameState: String;
    public let playerStats: PlayerStats;
    public let targetInfo: TargetInfo;
    public let activeSephirah: CName;
    public let timestamp: Float;
}

public struct PlayerStats {
    public let health: Float;
    public let stamina: Float;
    public let ram: Int32;
    public let cyberware: array<CName>;
}

public struct TargetInfo {
    public let entityId: EntityID;
    public let type: String;
    public let health: Float;
    public let armor: Float;
    public let cyberware: array<CName>;
}