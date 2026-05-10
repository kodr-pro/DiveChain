import { Link } from "react-router-dom";
import {
  DIVE_MODE_LABELS,
  DIVE_PURPOSE_LABELS,
  DiveMode,
  DivePurpose,
  UnitSystem,
  UNIT_SYSTEM_LABELS,
} from "../lib/contracts";

interface DiveCardProps {
  id: bigint;
  diveDate: bigint;
  maxDepth: number;
  bottomTimeMinutes: number;
  mode: number;
  purpose: number;
  units: number;
  location?: string;
  isVoided?: boolean;
  attestationCount?: number;
}

function formatDepth(depth: number, units: UnitSystem): string {
  return units === UnitSystem.Metric ? `${depth}m` : `${depth}ft`;
}

function formatDuration(minutes: number): string {
  if (minutes < 60) return `${minutes}min`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m > 0 ? `${h}h ${m}m` : `${h}h`;
}

function formatDate(timestamp: bigint): string {
  const epochMs = Number(timestamp) * 1000;
  return new Date(epochMs).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export default function DiveCard({
  id,
  diveDate,
  maxDepth,
  bottomTimeMinutes,
  mode,
  purpose,
  units,
  location,
  isVoided,
  attestationCount,
}: DiveCardProps) {
  return (
    <Link
      to={`/logbook/${id.toString()}`}
      className="block no-underline"
    >
      <div
        className={`rounded-xl border p-4 transition-all hover:border-teal/50 hover:shadow-lg hover:shadow-teal/5 ${
          isVoided
            ? "border-danger/30 bg-danger/5 opacity-60"
            : "border-card-border bg-card"
        }`}
      >
        <div className="flex items-start justify-between mb-2">
          <div>
            <h3 className="text-sm font-semibold text-white">
              Dive #{id.toString()}
            </h3>
            <p className="text-xs text-gray-400">{formatDate(diveDate)}</p>
          </div>
          <span className="text-xs px-2 py-1 rounded-full bg-teal/10 text-teal font-medium">
            {DIVE_MODE_LABELS[mode as DiveMode] ?? "Unknown"}
          </span>
        </div>

        <div className="grid grid-cols-3 gap-3 mt-3 text-center">
          <div>
            <p className="text-lg font-bold text-surf">
              {formatDepth(maxDepth, units as UnitSystem)}
            </p>
            <p className="text-[10px] text-gray-500 uppercase tracking-wider">Depth</p>
          </div>
          <div>
            <p className="text-lg font-bold text-surf">
              {formatDuration(bottomTimeMinutes)}
            </p>
            <p className="text-[10px] text-gray-500 uppercase tracking-wider">Duration</p>
          </div>
          <div>
            <p className="text-lg font-bold text-surf">
              {attestationCount ?? 0}
            </p>
            <p className="text-[10px] text-gray-500 uppercase tracking-wider">Attested</p>
          </div>
        </div>

        {location && (
          <p className="text-xs text-gray-400 mt-2 truncate">&#128205; {location}</p>
        )}

        <div className="flex items-center gap-2 mt-2">
          <span className="text-[10px] px-2 py-0.5 rounded bg-navy/50 text-gray-300">
            {DIVE_PURPOSE_LABELS[purpose as DivePurpose] ?? "Unknown"}
          </span>
          <span className="text-[10px] px-2 py-0.5 rounded bg-navy/50 text-gray-300">
            {UNIT_SYSTEM_LABELS[units as UnitSystem] ?? "Unknown"}
          </span>
        </div>

        {isVoided && (
          <div className="mt-2 text-xs text-danger font-medium">VOIDED</div>
        )}
      </div>
    </Link>
  );
}
