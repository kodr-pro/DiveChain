import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { useDiveLog } from "../hooks/useDiveLog";
import {
  BiologicalSex,
  UnitSystem,
  BIOLOGICAL_SEX_LABELS,
  UNIT_SYSTEM_LABELS,
} from "../lib/contracts";

const BIOLOGICAL_SEX_LABELS_LOCAL = BIOLOGICAL_SEX_LABELS;

export default function Profile() {
  const { isConnected, address } = useAccount();
  const [contractAddress, setContractAddress] = useLocalStorage<string>("divechain_contract", "");

  const {
    profile,
    owner,
    diveCount,
    isOwner,
    updateProfile,
    isPending,
    isConfirming,
  } = useDiveLog(contractAddress as `0x${string}` | undefined);

  const [editAddress, setEditAddress] = useState(contractAddress);
  const [name, setName] = useState("");
  const [age, setAge] = useState(0);
  const [height, setHeight] = useState(0);
  const [weight, setWeight] = useState(0);
  const [sex, setSex] = useState<BiologicalSex>(BiologicalSex.Unspecified);
  const [units, setUnits] = useState<UnitSystem>(UnitSystem.Metric);

  useEffect(() => {
    if (profile) {
      const p = profile as Record<string, unknown>;
      setName(p.name as string);
      setAge(Number(p.age));
      setHeight(Number(p.height));
      setWeight(Number(p.weight));
      setSex(Number(p.sex) as BiologicalSex);
      setUnits(Number(p.units) as UnitSystem);
    }
  }, [profile]);

  if (!isConnected) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-400">Connect your wallet to view profile.</p>
      </div>
    );
  }

  const handleSaveAddress = () => {
    if (editAddress.startsWith("0x") && editAddress.length === 42) {
      setContractAddress(editAddress);
    }
  };

  const handleUpdateProfile = () => {
    updateProfile(name, age, height, weight, sex, units);
  };

  return (
    <div className="max-w-lg mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-white">Profile</h1>

      <div className="bg-card border border-card-border rounded-xl p-6 space-y-4">
        <h2 className="text-lg font-semibold text-surf">Wallet</h2>
        <div className="text-sm font-mono text-gray-300 break-all">{address}</div>
      </div>

      <div className="bg-card border border-card-border rounded-xl p-6 space-y-4">
        <h2 className="text-lg font-semibold text-surf">Contract Address</h2>
        <div className="flex gap-2">
          <input
            type="text"
            value={editAddress}
            onChange={(e) => setEditAddress(e.target.value)}
            placeholder="0x..."
            className="flex-1 bg-deep border border-card-border rounded-lg px-3 py-2 text-white text-sm font-mono focus:border-teal focus:outline-none"
          />
          <button
            onClick={handleSaveAddress}
            className="px-4 py-2 bg-teal text-white text-sm rounded-lg hover:bg-teal/80"
          >
            Save
          </button>
        </div>
        {contractAddress && (
          <>
            <div className="text-xs text-gray-500">
              Owner: {owner ? `${owner.slice(0, 6)}...${owner.slice(-4)}` : "Loading..."}
              {isOwner ? (
                <span className="text-kelp ml-2">(you)</span>
              ) : (
                <span className="text-warn ml-2">(not owner)</span>
              )}
            </div>
            <div className="text-xs text-gray-500">
              Total dives: {diveCount?.toString() ?? "Loading..."}
            </div>
          </>
        )}
      </div>

      {contractAddress && Boolean(profile) && (
        <div className="bg-card border border-card-border rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-semibold text-surf">Diver Profile</h2>

          <div>
            <label className="block text-sm text-gray-400 mb-1">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              disabled={!isOwner}
              className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none disabled:opacity-50"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Age</label>
              <input
                type="number"
                value={age}
                onChange={(e) => setAge(Number(e.target.value))}
                disabled={!isOwner}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none disabled:opacity-50"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Height</label>
              <input
                type="number"
                value={height}
                onChange={(e) => setHeight(Number(e.target.value))}
                disabled={!isOwner}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none disabled:opacity-50"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Weight</label>
              <input
                type="number"
                value={weight}
                onChange={(e) => setWeight(Number(e.target.value))}
                disabled={!isOwner}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none disabled:opacity-50"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Sex</label>
              <select
                value={sex}
                onChange={(e) => setSex(Number(e.target.value) as BiologicalSex)}
                disabled={!isOwner}
                className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none disabled:opacity-50"
              >
                {Object.entries(BIOLOGICAL_SEX_LABELS_LOCAL).map(([val, label]) => (
                  <option key={val} value={val}>{label}</option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm text-gray-400 mb-1">Units</label>
            <select
              value={units}
              onChange={(e) => setUnits(Number(e.target.value) as UnitSystem)}
              disabled={!isOwner}
              className="w-full bg-deep border border-card-border rounded-lg px-3 py-2 text-white focus:border-teal focus:outline-none disabled:opacity-50"
            >
              {Object.entries(UNIT_SYSTEM_LABELS).map(([val, label]) => (
                <option key={val} value={val}>{label}</option>
              ))}
            </select>
          </div>

          {isOwner && (
            <button
              onClick={handleUpdateProfile}
              disabled={isPending || isConfirming}
              className="w-full py-3 rounded-xl bg-teal text-white font-semibold hover:bg-teal/80 disabled:opacity-50 transition-colors"
            >
              {isPending ? "Confirm..." : isConfirming ? "Updating..." : "Update Profile"}
            </button>
          )}
        </div>
      )}
    </div>
  );
}
