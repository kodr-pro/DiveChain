import { useAccount } from "wagmi";
import { Link } from "react-router-dom";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { useDiveLog } from "../hooks/useDiveLog";
import DiveCard from "../components/DiveCard";

export default function Logbook() {
  const { isConnected } = useAccount();
  const [contractAddress] = useLocalStorage<string>("divechain_contract", "");
  const { diveCount, allDiveIds, isOwner } = useDiveLog(
    contractAddress as `0x${string}` | undefined,
  );

  if (!isConnected) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-400">Connect your wallet to view your logbook.</p>
      </div>
    );
  }

  if (!contractAddress) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-400 mb-4">No dive log contract configured.</p>
        <Link
          to="/deploy"
          className="px-4 py-2 bg-teal rounded-lg text-white no-underline text-sm"
        >
          Deploy One Now
        </Link>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-white">Logbook</h1>
        <div className="flex items-center gap-3">
          <span className="text-sm text-gray-400">
            {diveCount !== undefined ? `${diveCount.toString()} dives` : "Loading..."}
          </span>
          {isOwner && (
            <Link
              to="/log-dive"
              className="px-4 py-2 bg-teal rounded-lg text-white no-underline text-sm font-medium"
            >
              + Log Dive
            </Link>
          )}
        </div>
      </div>

      <div className="text-xs text-gray-500 mb-4 break-all">
        Contract: {contractAddress}
      </div>

      {!allDiveIds || allDiveIds.length === 0 ? (
        <div className="text-center py-16">
          <div className="text-4xl mb-4">&#127754;</div>
          <p className="text-gray-400">No dives logged yet.</p>
          {isOwner && (
            <Link
              to="/log-dive"
              className="inline-block mt-4 px-4 py-2 bg-teal rounded-lg text-white no-underline text-sm"
            >
              Log Your First Dive
            </Link>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {allDiveIds.map((id) => (
            <DiveCardWrapper
              key={id.toString()}
              contractAddress={contractAddress as `0x${string}`}
              diveId={id}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function DiveCardWrapper({
  contractAddress,
  diveId,
}: {
  contractAddress: `0x${string}`;
  diveId: bigint;
}) {
  const { useDive, useVoidInfo, useAttestations } = useDiveLog(contractAddress);
  const { data: dive } = useDive(diveId);
  const { data: voidInfo } = useVoidInfo(diveId);
  const { data: attestations } = useAttestations(diveId);

  if (!dive) return null;

  const d = dive as Record<string, unknown>;
  const data = d.data as Record<string, unknown>;
  const env = d.env as Record<string, unknown>;

  return (
    <DiveCard
      id={diveId}
      diveDate={d.diveDate as bigint}
      maxDepth={Number(data?.maxDepth ?? 0)}
      bottomTimeMinutes={Number(data?.bottomTimeMinutes ?? 0)}
      mode={Number(data?.mode ?? 0)}
      purpose={Number(data?.purpose ?? 0)}
      units={Number(d.units ?? 0)}
      location={env?.location as string | undefined}
      isVoided={voidInfo ? (voidInfo as Record<string, unknown>).isVoided as boolean : false}
      attestationCount={attestations ? (attestations as unknown[]).length : 0}
    />
  );
}
