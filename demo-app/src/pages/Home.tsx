import { useAccount } from "wagmi";
import { Link } from "react-router-dom";

export default function Home() {
  const { isConnected } = useAccount();

  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
      <div className="text-6xl mb-6">&#128038;</div>
      <h1 className="text-4xl md:text-5xl font-bold mb-4">
        <span className="bg-gradient-to-r from-teal via-surf to-cyan bg-clip-text text-transparent">
          Divechain
        </span>
      </h1>
      <p className="text-lg text-gray-400 max-w-xl mb-8">
        Your sovereign, on-chain dive log. Own your diving history with
        cryptographic attestations on Avalanche.
      </p>

      {!isConnected ? (
        <div className="bg-card border border-card-border rounded-xl p-8 max-w-md">
          <p className="text-gray-300 mb-4">
            Connect your wallet to get started with your sovereign dive log.
          </p>
          <p className="text-sm text-gray-500">
            Use the <strong className="text-surf">Connect Wallet</strong> button in the top right.
          </p>
        </div>
      ) : (
        <div className="flex flex-col sm:flex-row gap-4">
          <Link
            to="/deploy"
            className="px-6 py-3 rounded-xl bg-teal text-white font-semibold no-underline hover:bg-teal/80 transition-colors"
          >
            Deploy New Log
          </Link>
          <Link
            to="/log-dive"
            className="px-6 py-3 rounded-xl border border-teal text-teal font-semibold no-underline hover:bg-teal/10 transition-colors"
          >
            Log a Dive
          </Link>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-16 w-full max-w-3xl">
        <div className="bg-card border border-card-border rounded-xl p-6">
          <div className="text-3xl mb-3">&#128274;</div>
          <h3 className="font-semibold text-white mb-2">Sovereign</h3>
          <p className="text-sm text-gray-400">
            Your dive data lives in a contract you own. No central authority can alter your records.
          </p>
        </div>
        <div className="bg-card border border-card-border rounded-xl p-6">
          <div className="text-3xl mb-3">&#9989;</div>
          <h3 className="font-semibold text-white mb-2">Attested</h3>
          <p className="text-sm text-gray-400">
            Get cryptographic signatures from dive buddies to verify your dives really happened.
          </p>
        </div>
        <div className="bg-card border border-card-border rounded-xl p-6">
          <div className="text-3xl mb-3">&#9889;</div>
          <h3 className="font-semibold text-white mb-2">On-Chain</h3>
          <p className="text-sm text-gray-400">
            Immutable records on Avalanche. Fast finality, low fees, and built for the real world.
          </p>
        </div>
      </div>
    </div>
  );
}
