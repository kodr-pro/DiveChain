import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Link, Outlet, useLocation } from "react-router-dom";
import { useAccount } from "wagmi";

const NAV_ITEMS = [
  { path: "/", label: "Home" },
  { path: "/logbook", label: "Logbook" },
  { path: "/log-dive", label: "Log Dive" },
  { path: "/deploy", label: "Deploy" },
];

export default function Layout() {
  const { isConnected } = useAccount();
  const location = useLocation();

  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-card-border bg-deep/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-2 text-xl font-bold text-surf no-underline">
            <span className="text-2xl">&#128038;</span>
            <span className="bg-gradient-to-r from-teal to-surf bg-clip-text text-transparent">
              Divechain
            </span>
          </Link>

          <nav className="hidden md:flex items-center gap-1">
            {NAV_ITEMS.map((item) => (
              <Link
                key={item.path}
                to={item.path}
                className={`px-3 py-2 rounded-lg text-sm font-medium no-underline transition-colors ${
                  location.pathname === item.path
                    ? "bg-teal/20 text-surf"
                    : "text-gray-400 hover:text-white hover:bg-white/5"
                } ${!isConnected && item.path !== "/" ? "opacity-50 pointer-events-none" : ""}`}
              >
                {item.label}
              </Link>
            ))}
          </nav>

          <ConnectButton />
        </div>
      </header>

      <main className="flex-1 max-w-6xl w-full mx-auto px-4 py-8">
        <Outlet />
      </main>

      <footer className="border-t border-card-border py-6 text-center text-sm text-gray-500">
        <p>Divechain - Sovereign Dive Log</p>
      </footer>

      {isConnected && (
        <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-deep border-t border-card-border flex justify-around py-2 z-50">
          {NAV_ITEMS.map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={`px-3 py-1 rounded text-xs font-medium no-underline ${
                location.pathname === item.path
                  ? "text-surf"
                  : "text-gray-400"
              }`}
            >
              {item.label}
            </Link>
          ))}
        </nav>
      )}
    </div>
  );
}
