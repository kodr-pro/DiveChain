import { useState } from "react";
import { useAccount, useDeployContract, useWaitForTransactionReceipt } from "wagmi";
import { useLocalStorage } from "../hooks/useLocalStorage";
import {
  SOVEREIGN_DIVE_LOG_ABI,
  SOVEREIGN_DIVE_LOG_BYTECODE,
  BiologicalSex,
  UnitSystem,
  BIOLOGICAL_SEX_LABELS,
  UNIT_SYSTEM_LABELS,
} from "../lib/contracts";

export default function Deploy() {
  const { address } = useAccount();
  const [_setContractAddress] = useLocalStorage<string>("divechain_contract", "");

  const [name, setName] = useState("");
  const [age, setAge] = useState(30);
  const [height, setHeight] = useState(180);
  const [weight, setWeight] = useState(80);
  const [sex, setSex] = useState<BiologicalSex>(BiologicalSex.Unspecified);
  const [units, setUnits] = useState<UnitSystem>(UnitSystem.Metric);

  const { deployContract, data: txHash, isPending, error } = useDeployContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash: txHash,
  });

  const handleDeploy = () => {
    if (!address) return;
    deployContract({
      abi: SOVEREIGN_DIVE_LOG_ABI,
      bytecode: SOVEREIGN_DIVE_LOG_BYTECODE,
      args: [address, name, age, height, weight, sex, units],
    });
  };

  return (
    <div className="max-w-lg mx-auto">
      <h1 className="text-2xl font-bold text-white mb-6">Deploy Sovereign Dive Log</h1>

      <div className="bg-card border border-card-border rounded-xl p-6 space-y-4">
        <div>
          <label className="block text-sm text-gray-400 mb-1">Diver Name</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
            placeholder="Enter your name"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm text-gray-400 mb-1">Age</label>
            <input
              type="number"
              value={age}
              onChange={(e) => setAge(Number(e.target.value))}
              className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-400 mb-1">Height ({units === UnitSystem.Metric ? "cm" : "in"})</label>
            <input
              type="number"
              value={height}
              onChange={(e) => setHeight(Number(e.target.value))}
              className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-400 mb-1">Weight ({units === UnitSystem.Metric ? "kg" : "lbs"})</label>
            <input
              type="number"
              value={weight}
              onChange={(e) => setWeight(Number(e.target.value))}
              className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
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

        <div>
          <label className="block text-sm text-gray-400 mb-1">Biological Sex</label>
          <select
            value={sex}
            onChange={(e) => setSex(Number(e.target.value) as BiologicalSex)}
            className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none"
          >
            {Object.entries(BIOLOGICAL_SEX_LABELS).map(([val, label]) => (
              <option key={val} value={val}>{label}</option>
            ))}
          </select>
        </div>

        <button
          onClick={handleDeploy}
          disabled={isPending || isConfirming || !name}
          className="w-full py-3 rounded-xl bg-teal text-white font-semibold hover:bg-teal/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {isPending ? "Confirm in Wallet..." : isConfirming ? "Deploying..." : "Deploy Contract"}
        </button>

        {error && (
          <p className="text-sm text-danger">{error.message}</p>
        )}

        {isSuccess && txHash && (
          <div className="bg-kelp/10 border border-kelp/30 rounded-lg p-3">
            <p className="text-sm text-kelp font-medium">Contract deployed!</p>
            <p className="text-xs text-gray-400 mt-1 break-all">TX: {txHash}</p>
            <p className="text-xs text-gray-400 mt-2">
              Find your contract address from the transaction receipt and set it in the Profile page.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
