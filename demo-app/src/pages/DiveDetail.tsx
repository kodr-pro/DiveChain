import { useParams, Link, useNavigate } from "react-router-dom";
import { useState } from "react";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { useDiveLog } from "../hooks/useDiveLog";
import {
  DIVE_MODE_LABELS,
  DIVE_PURPOSE_LABELS,
  SUIT_TYPE_LABELS,
  BREATHING_GAS_LABELS,
  DECOMP_TYPE_LABELS,
  UNIT_SYSTEM_LABELS,
  UnitSystem,
  DiveMode,
  DivePurpose,
  SuitType,
  BreathingGas,
  DecompressionType,
} from "../lib/contracts";

export default function DiveDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [contractAddress] = useLocalStorage<string>("divechain_contract", "");
  const { useDive, useVoidInfo, useAttestations, voidDive, isOwner, isPending, isConfirming, isSuccess } = useDiveLog(
    contractAddress as `0x${string}` | undefined,
  );

  const diveId = id ? BigInt(id) : 0n;
  const { data: dive } = useDive(diveId);
  const { data: voidInfo } = useVoidInfo(diveId);
  const { data: attestations } = useAttestations(diveId);

  const [showVoidForm, setShowVoidForm] = useState(false);
  const [voidReason, setVoidReason] = useState("");
  const [supersededBy, setSupersededBy] = useState("0");

  if (!contractAddress) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-400">No contract configured.</p>
      </div>
    );
  }

  if (!dive) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-400">Loading dive...</p>
      </div>
    );
  }

  const d = dive as Record<string, unknown>;
  const data = d.data as Record<string, unknown>;
  const env = d.env as Record<string, unknown>;
  const decomp = d.decomp as Record<string, unknown>;
  const gas = d.gas as Record<string, unknown>;
  const isVoided = voidInfo ? (voidInfo as Record<string, unknown>).isVoided as boolean : false;

  const formatDate = (ts: bigint) =>
    new Date(Number(ts) * 1000).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });

  const handleVoid = () => {
    voidDive(diveId, BigInt(supersededBy), voidReason);
    setShowVoidForm(false);
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <button
          onClick={() => navigate(-1)}
          className="text-gray-400 hover:text-white transition-colors"
        >
          &larr; Back
        </button>
        <h1 className="text-2xl font-bold text-white">Dive #{id}</h1>
        {isVoided && (
          <span className="px-2 py-1 rounded text-xs font-bold bg-danger/20 text-danger">
            VOIDED
          </span>
        )}
      </div>

      <div className="bg-card border border-card-border rounded-xl p-6 space-y-6">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
          <div>
            <p className="text-2xl font-bold text-surf">{String(data?.maxDepth ?? 0)}</p>
            <p className="text-xs text-gray-500">
              {UNIT_SYSTEM_LABELS[Number(d.units) as UnitSystem] === "Metric" ? "meters" : "feet"} max depth
            </p>
          </div>
          <div>
            <p className="text-2xl font-bold text-surf">{String(data?.bottomTimeMinutes ?? 0)}</p>
            <p className="text-xs text-gray-500">bottom time (min)</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-surf">{String(data?.averageDepth ?? 0)}</p>
            <p className="text-xs text-gray-500">avg depth</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-surf">{attestations ? (attestations as unknown[]).length : 0}</p>
            <p className="text-xs text-gray-500">attestations</p>
          </div>
        </div>

        <div className="border-t border-card-border pt-4 space-y-3">
          <DetailRow label="Date" value={formatDate(d.diveDate as bigint)} />
          <DetailRow label="Mode" value={DIVE_MODE_LABELS[Number(data?.mode) as DiveMode] ?? "-"} />
          <DetailRow label="Purpose" value={DIVE_PURPOSE_LABELS[Number(data?.purpose) as DivePurpose] ?? "-"} />
          <DetailRow label="Suit" value={SUIT_TYPE_LABELS[Number(data?.suit) as SuitType] ?? "-"} />
          <DetailRow label="Units" value={UNIT_SYSTEM_LABELS[Number(d.units) as UnitSystem] ?? "-"} />
        </div>

        {env && (String(env.location ?? "") || String(env.waterTemp ?? "") || String(env.airTemp ?? "")) && (
          <div className="border-t border-card-border pt-4 space-y-3">
            <h3 className="text-sm font-semibold text-gray-300 uppercase tracking-wider">Environment</h3>
            {String(env.location ?? "") && <DetailRow label="Location" value={String(env.location)} />}
            {String(env.bottomType ?? "") && <DetailRow label="Bottom" value={String(env.bottomType)} />}
            <DetailRow label="Water Temp" value={`${String(env.waterTemp)}°`} />
            <DetailRow label="Air Temp" value={`${String(env.airTemp)}°`} />
            {String(env.weatherConditions ?? "") && <DetailRow label="Weather" value={String(env.weatherConditions)} />}
          </div>
        )}

        {gas && (
          <div className="border-t border-card-border pt-4 space-y-3">
            <h3 className="text-sm font-semibold text-gray-300 uppercase tracking-wider">Gas</h3>
            <DetailRow label="Type" value={BREATHING_GAS_LABELS[Number(gas.gasType) as BreathingGas] ?? "-"} />
            <DetailRow label="O2" value={`${gas.o2Percent}%`} />
            <DetailRow label="He" value={`${gas.hePercent}%`} />
          </div>
        )}

        {decomp && Number(decomp.decompType) !== 0 && (
          <div className="border-t border-card-border pt-4 space-y-3">
            <h3 className="text-sm font-semibold text-gray-300 uppercase tracking-wider">Decompression</h3>
            <DetailRow label="Type" value={DECOMP_TYPE_LABELS[Number(decomp.decompType) as DecompressionType] ?? "-"} />
            <DetailRow label="Total Deco Time" value={`${decomp.totalDecompTimeMinutes} min`} />
          </div>
        )}

        {String(d.remarks ?? "") && (
          <div className="border-t border-card-border pt-4">
            <h3 className="text-sm font-semibold text-gray-300 uppercase tracking-wider mb-2">Remarks</h3>
            <p className="text-sm text-gray-400">{String(d.remarks)}</p>
          </div>
        )}

        {attestations && Array.isArray(attestations) && (attestations as unknown[]).length > 0 ? (
          <div className="border-t border-card-border pt-4">
            <h3 className="text-sm font-semibold text-gray-300 uppercase tracking-wider mb-2">Attestations</h3>
            <div className="space-y-2">
              {(attestations as Record<string, unknown>[]).map((a, i) => (
                <div key={i} className="flex items-center gap-2 text-sm">
                  <span className="text-kelp">&#9989;</span>
                  <span className="text-gray-300 font-mono text-xs">
                    {String(a.attester).slice(0, 6)}...{String(a.attester).slice(-4)}
                  </span>
                  <span className="text-gray-500 text-xs">
                    {new Date(Number(a.attestedAt) * 1000).toLocaleDateString()}
                  </span>
                </div>
              ))}
            </div>
          </div>
        ) : null}

        {isOwner && !isVoided && (
          <div className="border-t border-card-border pt-4">
            {!showVoidForm ? (
              <button
                onClick={() => setShowVoidForm(true)}
                className="text-sm text-danger hover:underline"
              >
                Void this dive
              </button>
            ) : (
              <div className="space-y-3 bg-danger/5 rounded-lg p-4">
                <input
                  type="text"
                  value={voidReason}
                  onChange={(e) => setVoidReason(e.target.value)}
                  placeholder="Reason for voiding"
                  className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white text-sm focus:border-danger focus:outline-none"
                />
                <input
                  type="number"
                  value={supersededBy}
                  onChange={(e) => setSupersededBy(e.target.value)}
                  placeholder="Superseded by dive ID (0 = none)"
                  className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white text-sm focus:border-danger focus:outline-none"
                />
                <div className="flex gap-2">
                  <button
                    onClick={handleVoid}
                    disabled={isPending || isConfirming || !voidReason}
                    className="px-4 py-2 bg-danger text-white text-sm rounded-lg disabled:opacity-50"
                  >
                    {isPending ? "Confirm..." : isConfirming ? "Voiding..." : "Confirm Void"}
                  </button>
                  <button
                    onClick={() => setShowVoidForm(false)}
                    className="px-4 py-2 text-gray-400 text-sm"
                  >
                    Cancel
                  </button>
                </div>
                {isSuccess && <p className="text-sm text-kelp">Dive voided.</p>}
              </div>
            )}
          </div>
        )}

        {isVoided && Boolean(voidInfo) && (
          <div className="border-t border-card-border pt-4">
            <div className="bg-danger/5 rounded-lg p-4 text-sm space-y-1">
              <p className="text-danger font-medium">This dive has been voided</p>
              <p className="text-gray-400">Reason: {String((voidInfo as Record<string, unknown>).reason)}</p>
              {Boolean((voidInfo as Record<string, unknown>).supersededById) && (
                <p className="text-gray-400">
                  Superseded by:{" "}
                  <Link
                    to={`/logbook/${((voidInfo as Record<string, unknown>).supersededById as bigint).toString()}`}
                    className="text-surf underline"
                  >
                    Dive #{((voidInfo as Record<string, unknown>).supersededById as bigint).toString()}
                  </Link>
                </p>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <span className="text-sm text-gray-400">{label}</span>
      <span className="text-sm text-white">{value}</span>
    </div>
  );
}
