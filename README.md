# Divechain

Immutable, on-chain dive logs for professional and recreational divers. No databases to delete. No services to shut down. Your dive history, forever.

## Problem

Dive logs are critical safety and compliance records. Today they live in:

- Paper logbooks that get lost, damaged, or destroyed
- Centralized apps and databases that get shut down
- Institutional systems that disappear when organizations change

Divers lose access to their own history. Organizations lose institutional knowledge. The data that proves qualification, tracks decompression history, and ensures safety should outlast any single service.

## Solution

Divechain stores dive logs as EVM smart contract data. Each diver gets their own contract deployed via a registry. The data is on-chain, permanent, and owned by the diver.

## Architecture

```
DiveLogRegistry (factory)
  |
  +-- DiveLogBook (deployed per-diver)
  |     |-- DiverProfile (name, age, height, weight, sex, units)
  |     |-- DiveLog[] (append-only log entries)
  |     |-- Decompression data per dive
  |     |-- Gas mixture data per dive
  |     +-- Environment data per dive
  |
  +-- DiveLogBook (another diver)
  ...
```

**DiveLogRegistry** — Deployed once. Users call `registerDiver()` which deploys a `DiveLogBook` contract unique to their address. Maps `address → logBookAddress`.

**DiveLogBook** — Per-diver contract. Stores an append-only list of dive logs with full decompression, gas, and environment data. Only the owner can write. Anyone can read.

## Data Standard

The dive log schema is derived from two U.S. military diving log standards:

- **DD Form 2544** (Feb 2025) — U.S. Navy Diving Log, NAVSEA/Naval Safety Center
- **ENG Form 4615** (Feb 2021) — U.S. Army Corps of Engineers Dive Log, ER 385-1-86

See [docs/ERC-dive-log-standard.md](docs/ERC-dive-log-standard.md) for the full ERC specification and [docs/dive-data-standard.md](docs/dive-data-standard.md) for field-level documentation.

### Unit Systems

Every dive and every diver profile carries a `UnitSystem` enum (`Imperial` or `Metric`). This determines how numeric fields should be interpreted:

| Field | Imperial | Metric |
|-------|----------|--------|
| Temperature | °F | °C |
| Depth | Feet (FSW) | Meters (MSW) |
| Height | Inches | Centimeters |
| Weight | Pounds | Kilograms |
| Pressure | PSI | Bar |
| Current | Knots | Knots |

## Project Structure

```
Divechain/
├── src/
│   ├── interfaces/
│   │   ├── IDiveLogTypes.sol    # Shared enums and structs
│   │   ├── IDiveLogBook.sol     # Log book interface
│   │   ├── IDiveLogRegistry.sol # Registry interface
│   │   └── IERC165.sol          # ERC-165 interface
│   ├── DiveLogBook.sol          # Per-diver log storage contract
│   └── DiveLogRegistry.sol      # Factory/registry contract
├── script/
│   └── Deploy.s.sol             # Deployment script
├── test/
│   ├── DiveLogBook.t.sol        # Log book tests + fuzz tests
│   └── DiveLogRegistry.t.sol    # Registry tests
├── docs/
│   ├── ERC-dive-log-standard.md  # ERC standard proposal
│   └── dive-data-standard.md     # Field definitions and conventions
├── references/                  # Source military dive log forms (PDF)
└── foundry.toml
```

## Build

Requires [Foundry](https://book.getfoundry.sh/).

```shell
forge build
```

## Test

```shell
forge test
```

## Deploy

```shell
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <KEY> --broadcast
```

## Usage

### 1. Register a diver

```solidity
DiveLogRegistry registry = DiveLogRegistry(REGISTRY_ADDRESS);
address myLogBook = registry.registerDiver(
    "Smith, John A.",  // name
    32,                // age
    71,                // height (inches or cm per UnitSystem)
    185,               // weight (lbs or kg per UnitSystem)
    BiologicalSex.Male,// sex
    UnitSystem.Imperial
);
```

### 2. Log a dive

```solidity
DiveLogBook logBook = DiveLogBook(myLogBook);

logBook.logDive(
    1714521600,                  // diveDate (unix timestamp)
    UnitSystem.Imperial,         // units for this dive
    DiveData({                   // core dive data
        leaveSurfaceTime: 1714521600,
        leaveBottomTime: 1714522440,
        reachSurfaceTime: 1714522700,
        bottomTimeMinutes: 14,
        maxDepth: 95,
        averageDepth: 75,
        mode: DiveMode.SSA,
        purpose: DivePurpose.Inspection,
        suit: SuitType.Dry
    }),
    Environment({                // conditions
        airTemp: 72,
        waterTemp: 58,
        currentKnots: 1,
        location: "Naval Station Norfolk, Pier 3",
        bottomType: "Mud/Silt",
        weatherConditions: "Clear"
    }),
    Decompression({              // decompression data
        decompType: DecompressionType.Standard,
        totalDecompTimeMinutes: 6,
        maxDepthAttained: 95,
        tableSchedule: "",
        repetitiveGroup: 0x44,   // 'D'
        surfaceIntervalMinutes: 0,
        newRepetitiveGroup: 0x00
    }),
    GasData({                    // breathing gas data
        gasType: BreathingGas.Air,
        o2Percent: 21,
        hePercent: 0,
        n2Percent: 79,
        cylinderPressureIn: 3000,
        cylinderPressureOut: 1200,
        gasConsumed: 1800,
        bailoutPressure: 2800
    }),
    "Hull inspection, starboard side. Good visibility."  // remarks
);
```

### 3. Retrieve dive logs

```solidity
// Get a single dive
DiveLog memory dive = logBook.getDive(1);

// Get all dive IDs
uint256[] memory allIds = logBook.getAllDiveIds();

// Get dives by date
uint256[] memory ids = logBook.getDivesByDate(1714521600);

// Get multiple dives at once
DiveLog[] memory dives = logBook.getMultipleDives(ids);

// Get diver profile
DiverProfile memory p = logBook.profile();
```

## License

MIT
