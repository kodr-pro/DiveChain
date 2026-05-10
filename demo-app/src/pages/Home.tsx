import { useState } from "react";
import { useAccount } from "wagmi";
import { useNavigate } from "react-router-dom";
import { useDiveContract } from "../contexts/DiveContractContext";

export default function Home() {
  const { isConnected } = useAccount();
  const { hasContract, setContract } = useDiveContract();
  const navigate = useNavigate();
  const [showImport, setShowImport] = useState(false);
  const [importAddr, setImportAddr] = useState("");

  return (
    <div className="flex flex-col items-center text-center relative">
      <div className="relative mb-6 mt-8">
        <div className="text-7xl mb-2">{"\u{1F42C}"}</div>
        <div className="absolute inset-0 rounded-full bg-surf/5 animate-[sonar-pulse_3s_ease-out_infinite]" />
      </div>

      <h1 className="text-4xl md:text-5xl font-bold mb-3 tracking-tight">
        <span className="bg-gradient-to-r from-teal via-surf to-bubble bg-clip-text text-transparent">
          Divechain
        </span>
      </h1>
      <p className="text-base text-gray-400 max-w-md mb-8 leading-relaxed">
        Your sovereign, on-chain dive log. Cryptographically verified diving history on Avalanche.
      </p>

      {!isConnected ? (
        <div className="glass-card p-8 max-w-sm">
          <div className="text-4xl mb-4">{"\u{1F517}"}</div>
          <p className="text-gray-300 mb-3 text-sm">Connect your wallet to access your dive log.</p>
          <p className="text-xs text-gray-500">
            Click <strong className="text-surf">Connect Wallet</strong> in the top right corner.
          </p>
        </div>
      ) : hasContract ? (
        <div className="flex flex-col sm:flex-row gap-3">
          <button onClick={() => navigate("/logbook")} className="btn-primary">
            {"\u{1F4D6}"} Open Logbook
          </button>
          <button onClick={() => navigate("/log-dive")} className="btn-ghost">
            {"\u{1F9BE}"} Log a Dive
          </button>
        </div>
      ) : (
        <div className="flex flex-col items-center gap-4">
          <div className="flex flex-col sm:flex-row gap-3">
            <button onClick={() => navigate("/deploy")} className="btn-primary text-lg px-8 py-4">
              {"\u{1F680}"} Create New Dive Log
            </button>
            <button onClick={() => setShowImport(true)} className="btn-ghost">
              {"\u{1F517}"} Connect Existing Log
            </button>
          </div>

          {showImport && (
            <div className="glass-card p-6 max-w-md w-full">
              <p className="text-sm text-gray-300 mb-3">
                Already have a deployed SovereignDiveLog? Paste the contract address:
              </p>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={importAddr}
                  onChange={(e) => setImportAddr(e.target.value)}
                  placeholder="0x..."
                />
                <button
                  onClick={() => {
                    if (importAddr.startsWith("0x") && importAddr.length === 42) {
                      setContract(importAddr);
                      navigate("/logbook");
                    }
                  }}
                  disabled={importAddr.length !== 42}
                  className="btn-primary text-sm px-4 py-2 shrink-0"
                >
                  Connect
                </button>
              </div>
              <button onClick={() => setShowImport(false)} className="text-xs text-gray-500 mt-3 hover:text-gray-300">
                Cancel
              </button>
            </div>
          )}
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mt-16 w-full max-w-4xl">
        <button onClick={() => navigate("/dive-sites")} className="glass-card p-5 text-left no-underline hover:border-bismuth/30 transition-all cursor-pointer group">
          <div className="w-9 h-9 rounded-lg bg-teal/10 flex items-center justify-center text-lg mb-3">{"\u{1F30D}"}</div>
          <h3 className="font-semibold text-white text-sm mb-1 group-hover:text-surf transition-colors">Dive Sites</h3>
          <p className="text-xs text-gray-500">Explore global dive regions, conditions & top sites.</p>
        </button>
        <button onClick={() => navigate("/tools")} className="glass-card p-5 text-left no-underline hover:border-bismuth/30 transition-all cursor-pointer group">
          <div className="w-9 h-9 rounded-lg bg-teal/10 flex items-center justify-center text-lg mb-3">{"\u{1F527}"}</div>
          <h3 className="font-semibold text-white text-sm mb-1 group-hover:text-surf transition-colors">Dive Tools</h3>
          <p className="text-xs text-gray-500">Gas mix calculator, NDL planner & SAC rate tool.</p>
        </button>
        <button onClick={() => navigate("/community")} className="glass-card p-5 text-left no-underline hover:border-bismuth/30 transition-all cursor-pointer group">
          <div className="w-9 h-9 rounded-lg bg-teal/10 flex items-center justify-center text-lg mb-3">{"\u{1F465}"}</div>
          <h3 className="font-semibold text-white text-sm mb-1 group-hover:text-surf transition-colors">Community</h3>
          <p className="text-xs text-gray-500">Connect with divers, share experiences & tips.</p>
        </button>
        <button onClick={() => navigate("/logbook")} className="glass-card p-5 text-left no-underline hover:border-bismuth/30 transition-all cursor-pointer group">
          <div className="w-9 h-9 rounded-lg bg-teal/10 flex items-center justify-center text-lg mb-3">{"\u{1F4D6}"}</div>
          <h3 className="font-semibold text-white text-sm mb-1 group-hover:text-surf transition-colors">My Logbook</h3>
          <p className="text-xs text-gray-500">On-chain dive log with buddy attestations.</p>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mt-12 w-full max-w-3xl pb-8">
        <div className="glass-card p-5">
          <div className="w-9 h-9 rounded-lg bg-teal/10 flex items-center justify-center text-lg mb-3">{"\u{1F512}"}</div>
          <h3 className="font-semibold text-white mb-2 text-sm">Sovereign Ownership</h3>
          <p className="text-xs text-gray-400 leading-relaxed">
            Your dive data lives in a contract you own. No central authority can alter your records.
          </p>
        </div>
        <div className="glass-card p-5">
          <div className="w-9 h-9 rounded-lg bg-teal/10 flex items-center justify-center text-lg mb-3">{"\u2705"}</div>
          <h3 className="font-semibold text-white mb-2 text-sm">Buddy Attestations</h3>
          <p className="text-xs text-gray-400 leading-relaxed">
            EIP-712 cryptographic signatures from dive buddies verify your dives happened.
          </p>
        </div>
        <div className="glass-card p-5">
          <div className="w-9 h-9 rounded-lg bg-teal/10 flex items-center justify-center text-lg mb-3">{"\u26A1"}</div>
          <h3 className="font-semibold text-white mb-2 text-sm">Immutable on Avalanche</h3>
          <p className="text-xs text-gray-400 leading-relaxed">
            Sub-second finality, low fees, permanent storage. Your dives outlast any service.
          </p>
        </div>
      </div>
    </div>
  );
}
