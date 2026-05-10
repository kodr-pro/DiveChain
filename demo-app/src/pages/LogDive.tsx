import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { useDiveLog } from "../hooks/useDiveLog";
import {
  UnitSystem,
  DiveMode,
  DivePurpose,
  SuitType,
  BreathingGas,
  DecompressionType,
  UNIT_SYSTEM_LABELS,
  DIVE_MODE_LABELS,
  DIVE_PURPOSE_LABELS,
  SUIT_TYPE_LABELS,
  BREATHING_GAS_LABELS,
  DECOMP_TYPE_LABELS,
} from "../lib/contracts";

export default function LogDive() {
  const navigate = useNavigate();
  const [contractAddress] = useLocalStorage<string>("divechain_contract", "");
  const { logDive, isPending, isConfirming, isSuccess, error } = useDiveLog(
    contractAddress as `0x${string}` | undefined,
  );

  const [diveDate, setDiveDate] = useState("");
  const [units, setUnits] = useState<UnitSystem>(UnitSystem.Metric);
  const [maxDepth, setMaxDepth] = useState(30);
  const [averageDepth, setAverageDepth] = useState(15);
  const [bottomTimeMinutes, setBottomTimeMinutes] = useState(45);
  const [mode, setMode] = useState<DiveMode>(DiveMode.SCUBA);
  const [purpose, setPurpose] = useState<DivePurpose>(DivePurpose.Recreational);
  const [suit, setSuit] = useState<SuitType>(SuitType.Wet);
  const [location, setLocation] = useState("");
  const [waterTemp, setWaterTemp] = useState(20);
  const [airTemp, setAirTemp] = useState(25);
  const [bottomType, setBottomType] = useState("");
  const [weatherConditions, setWeatherConditions] = useState("");
  const [decompType, setDecompType] = useState<DecompressionType>(DecompressionType.NoneDecomp);
  const [totalDecompTime, setTotalDecompTime] = useState(0);
  const [gasType, setGasType] = useState<BreathingGas>(BreathingGas.Air);
  const [o2Percent, setO2Percent] = useState(21);
  const [hePercent, setHePercent] = useState(0);
  const [remarks, setRemarks] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!contractAddress || !diveDate) return;

    const dateSeconds = BigInt(Math.floor(new Date(diveDate).getTime() / 1000));

    logDive({
      diveDate: dateSeconds,
      units,
      data: {
        leaveSurfaceTime: 0,
        leaveBottomTime: 0,
        reachSurfaceTime: 0,
        bottomTimeMinutes,
        maxDepth,
        averageDepth,
        mode,
        purpose,
        suit,
      },
      env: {
        airTemp,
        waterTemp,
        currentKnots: 0,
        location,
        bottomType,
        weatherConditions,
      },
      decomp: {
        decompType,
        totalDecompTimeMinutes: totalDecompTime,
        maxDepthAttained: maxDepth,
        tableSchedule: "0x0000000000000000000000000000000000000000000000000000000000000000",
        repetitiveGroup: "0x00",
        surfaceIntervalMinutes: 0,
        newRepetitiveGroup: "0x00",
      },
      gas: {
        gasType,
        o2Percent,
        hePercent,
        n2Percent: 100 - o2Percent - hePercent,
        cylinderPressureIn: 0,
        cylinderPressureOut: 0,
        gasConsumed: 0,
        bailoutPressure: 0,
      },
      remarks,
    });
  };

  if (!contractAddress) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-400">No dive log contract configured. Deploy one first.</p>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold text-white mb-6">Log a Dive</h1>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-card border border-card-border rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-semibold text-surf">Basic Info</h2>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Dive Date</label>
              <input
                type="date"
                value={diveDate}
                onChange={(e) => setDiveDate(e.target.value)}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
                required
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Unit System</label>
              <select
                value={units}
                onChange={(e) => setUnits(Number(e.target.value) as UnitSystem)}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              >
                {Object.entries(UNIT_SYSTEM_LABELS).map(([val, label]) => (
                  <option key={val} value={val}>{label}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Mode</label>
              <select
                value={mode}
                onChange={(e) => setMode(Number(e.target.value) as DiveMode)}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              >
                {Object.entries(DIVE_MODE_LABELS).map(([val, label]) => (
                  <option key={val} value={val}>{label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Purpose</label>
              <select
                value={purpose}
                onChange={(e) => setPurpose(Number(e.target.value) as DivePurpose)}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              >
                {Object.entries(DIVE_PURPOSE_LABELS).map(([val, label]) => (
                  <option key={val} value={val}>{label}</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="bg-card border border-card-border rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-semibold text-surf">Dive Data</h2>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm text-gray-400 mb-1">
                Max Depth ({units === UnitSystem.Metric ? "m" : "ft"})
              </label>
              <input
                type="number"
                value={maxDepth}
                onChange={(e) => setMaxDepth(Number(e.target.value))}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
                required
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">
                Avg Depth ({units === UnitSystem.Metric ? "m" : "ft"})
              </label>
              <input
                type="number"
                value={averageDepth}
                onChange={(e) => setAverageDepth(Number(e.target.value))}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Bottom Time (min)</label>
              <input
                type="number"
                value={bottomTimeMinutes}
                onChange={(e) => setBottomTimeMinutes(Number(e.target.value))}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm text-gray-400 mb-1">Suit Type</label>
            <select
              value={suit}
              onChange={(e) => setSuit(Number(e.target.value) as SuitType)}
              className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
            >
              {Object.entries(SUIT_TYPE_LABELS).map(([val, label]) => (
                <option key={val} value={val}>{label}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="bg-card border border-card-border rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-semibold text-surf">Environment</h2>

          <div>
            <label className="block text-sm text-gray-400 mb-1">Location</label>
            <input
              type="text"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              placeholder="e.g. Great Barrier Reef"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Water Temp ({units === UnitSystem.Metric ? "°C" : "°F"})</label>
              <input
                type="number"
                value={waterTemp}
                onChange={(e) => setWaterTemp(Number(e.target.value))}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Air Temp ({units === UnitSystem.Metric ? "°C" : "°F"})</label>
              <input
                type="number"
                value={airTemp}
                onChange={(e) => setAirTemp(Number(e.target.value))}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Bottom Type</label>
              <input
                type="text"
                value={bottomType}
                onChange={(e) => setBottomType(e.target.value)}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
                placeholder="e.g. Sand, Coral, Rock"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Weather</label>
              <input
                type="text"
                value={weatherConditions}
                onChange={(e) => setWeatherConditions(e.target.value)}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
                placeholder="e.g. Clear, Overcast"
              />
            </div>
          </div>
        </div>

        <div className="bg-card border border-card-border rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-semibold text-surf">Gas & Decompression</h2>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Breathing Gas</label>
              <select
                value={gasType}
                onChange={(e) => setGasType(Number(e.target.value) as BreathingGas)}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              >
                {Object.entries(BREATHING_GAS_LABELS).map(([val, label]) => (
                  <option key={val} value={val}>{label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Decompression Type</label>
              <select
                value={decompType}
                onChange={(e) => setDecompType(Number(e.target.value) as DecompressionType)}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              >
                {Object.entries(DECOMP_TYPE_LABELS).map(([val, label]) => (
                  <option key={val} value={val}>{label}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-400 mb-1">O2 %</label>
              <input
                type="number"
                value={o2Percent}
                onChange={(e) => setO2Percent(Number(e.target.value))}
                min={0}
                max={100}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">He %</label>
              <input
                type="number"
                value={hePercent}
                onChange={(e) => setHePercent(Number(e.target.value))}
                min={0}
                max={100}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              />
            </div>
          </div>

          {decompType !== DecompressionType.NoneDecomp && (
            <div>
              <label className="block text-sm text-gray-400 mb-1">Total Deco Time (min)</label>
              <input
                type="number"
                value={totalDecompTime}
                onChange={(e) => setTotalDecompTime(Number(e.target.value))}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
              />
            </div>
          )}
        </div>

        <div className="bg-card border border-card-border rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-semibold text-surf">Remarks</h2>
          <textarea
            value={remarks}
            onChange={(e) => setRemarks(e.target.value)}
            className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none min-h-[80px]"
            placeholder="Any notes about the dive..."
          />
        </div>

        <button
          type="submit"
          disabled={isPending || isConfirming}
          className="w-full py-3 rounded-xl bg-teal text-white font-semibold hover:bg-teal/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {isPending ? "Confirm in Wallet..." : isConfirming ? "Logging..." : "Log Dive"}
        </button>

        {error && <p className="text-sm text-danger text-center">{error.message}</p>}

        {isSuccess && (
          <div className="bg-kelp/10 border border-kelp/30 rounded-lg p-4 text-center">
            <p className="text-kelp font-medium">Dive logged successfully!</p>
            <button
              type="button"
              onClick={() => navigate("/logbook")}
              className="mt-2 text-sm text-surf underline"
            >
              View Logbook
            </button>
          </div>
        )}
      </form>
    </div>
  );
}
