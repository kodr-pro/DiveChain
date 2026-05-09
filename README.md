# Divechain

Sovereign, on-chain dive logs with cryptographic attestation. No registries. No silos. Your dive history, forever.

## ERC Status

**[EIP-XXXX: Dive Logbook Standard](https://github.com/ethereum/ERCs/pull/1735)** — Pull Request open for review in the official Ethereum ERCs repository.

## Philosophy

**Identity is the Address. Experience is the Contract. The Standard is the Language.**

This ERC defines a sovereign interface standard for dive logs. A diver's contract IS their logbook. Any tool speaking the `IDiveLog` interface can render a diver's entire career from a contract address and chain ID. No central registry required.

## Problem

Dive logs are critical safety and compliance records. Today they live in:

- Paper logbooks that get lost, damaged, or destroyed
- Centralized apps and databases that get shut down
- Institutional systems that disappear when organizations change
- Proprietary silos with no interoperability

Divers lose access to their own history. Organizations lose institutional knowledge. No cryptographic proof exists for buddy sign-offs, enabling "pencil-whipping" (faking logs).

## Solution

The **Sovereign Dive Log Standard** defines a single interface (`IDiveLog`) that any contract can implement:

- **Sovereign Identity** — No registry. A diver deploys their own contract. Their identity IS the contract address.
- **Corrective Ledger** — No edit/delete. Professional Void/Supersede mechanism maintains immutable integrity while allowing error correction.
- **Cryptographic Attestation** — EIP-712 typed signatures for buddy/instructor sign-offs. Eliminates pencil-whipping.
- **Permissionless Verifiability** — Any compliant tool can verify a diver's certifications and history from a contract address. No login required.
- **Hardware Interoperability** — EIP-712 typed data schema enables dive computers to sign complete dive profiles.

## Architecture

```
Any IDiveLog Contract (deployed by diver, agency, etc.)
├── DiverProfile (name, age, height, weight, sex, units)
├── DiveLog[] (append-only log entries)
│   ├── DiveData (depth, time, mode, purpose, suit)
│   ├── Environment (temp, location, conditions)
│   ├── Decompression (schedule, stops, repetitive groups)
│   └── GasData (breathing gas, pressures, consumption)
├── VoidInfo (void/supersede per dive — corrective ledger)
└── Attestation[] (EIP-712 signed buddy/instructor sign-offs)
```

Multiple implementations (PADI, NAUI, military, individual developers) can deploy their own versions while remaining fully interoperable with any front-end that speaks the standard.

## Data Standard

The dive log schema is derived from two U.S. military diving log standards:

- **DD Form 2544** (Feb 2025) — U.S. Navy Diving Log, NAVSEA/Naval Safety Center
- **ENG Form 4615** (Feb 2021) — U.S. Army Corps of Engineers Dive Log, ER 385-1-86

See [docs/eip-draft_dive_logbook.md](docs/eip-draft_dive_logbook.md) for the full ERC specification and [docs/dive-data-standard.md](docs/dive-data-standard.md) for field-level documentation.

## Project Structure

```
Divechain/
├── src/
│   ├── interfaces/                    # Core ERC Standard
│   │   ├── IERC165.sol               # ERC-165 interface detection
│   │   ├── IDiveLogTypes.sol         # Shared enums and structs
│   │   ├── IDiveLog.sol              # Sovereign dive log interface
│   │   └── IDiveLogTypedData.sol     # EIP-712 typed data library
│   └── SovereignDiveLog.sol          # Reference implementation
├── test/
│   └── SovereignDiveLog.t.sol        # Tests (42 passing)
├── script/
│   └── Deploy.s.sol                  # Deployment script
├── docs/
│   ├── eip-draft_dive_logbook.md     # EIP submission
│   └── dive-data-standard.md         # Field definitions and conventions
├── references/
│   ├── dd2544.pdf                    # U.S. Navy Diving Log (DD Form 2544)
│   └── Eng_Form_4615_2021Feb.pdf     # U.S. Army Corps of Engineers Dive Log
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

Set environment variables:
- `DIVER_ADDRESS` — The diver's EOA address (will be set as contract owner)
- `DIVER_NAME` — Full name
- `DIVER_AGE` — Age
- `DIVER_HEIGHT` — Height (inches or cm per unit system)
- `DIVER_WEIGHT` — Weight (lbs or kg per unit system)
- `DIVER_SEX` — 0=Male, 1=Female, 2=Unspecified
- `DIVER_UNITS` — 0=Imperial, 1=Metric

## Usage

### 1. Deploy a sovereign dive log

```solidity
SovereignDiveLog myLog = new SovereignDiveLog(
    msg.sender,           // owner
    "Smith, John A.",     // name
    32,                   // age
    71,                   // height
    185,                  // weight
    BiologicalSex.Male,   // sex
    UnitSystem.Imperial   // units
);
```

### 2. Log a dive

```solidity
myLog.logDive(
    1714521600,                  // diveDate
    UnitSystem.Imperial,         // units
    DiveData({
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
    Environment({
        airTemp: 72, waterTemp: 58, currentKnots: 1,
        location: "Naval Station Norfolk, Pier 3",
        bottomType: "Mud/Silt",
        weatherConditions: "Clear"
    }),
    Decompression({
        decompType: DecompressionType.Standard,
        totalDecompTimeMinutes: 6,
        maxDepthAttained: 95,
        tableSchedule: "USN 9-7",
        repetitiveGroup: 0x44, surfaceIntervalMinutes: 0,
        newRepetitiveGroup: 0x00
    }),
    GasData({
        gasType: BreathingGas.Air,
        o2Percent: 21, hePercent: 0, n2Percent: 79,
        cylinderPressureIn: 3000, cylinderPressureOut: 1200,
        gasConsumed: 1800, bailoutPressure: 2800
    }),
    "Hull inspection, starboard side."
);
```

### 3. Void a dive (corrective ledger)

```solidity
// Log corrected dive, then void the original
myLog.voidDive(5, 6, "Depth was recorded incorrectly");
// Dive #5 is now voided, superseded by #6
// Original data remains readable via getDive(5)
```

### 4. Attest a dive (buddy sign-off)

```solidity
// Buddy signs the EIP-712 typed data off-chain
bytes32 digest = DiveLogTypedData.attestationDigest(diveId, address(myLog), block.chainid);
(uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPrivateKey, digest);
bytes memory signature = abi.encodePacked(r, s, v);

// Anyone can submit the signature on-chain
myLog.attestDive(diveId, signature);
```

### 5. Query dive history

```solidity
// Verify compliance via IDiveLog interface
IDiveLog diveLog = IDiveLog(diverContractAddress);
assertTrue(diveLog.supportsInterface(type(IDiveLog).interfaceId));

uint256 totalDives = diveLog.getDiveCount();
DiveLog memory latestDive = diveLog.getDive(totalDives);
bool isVoided = diveLog.isDiveVoided(someDiveId);
Attestation[] memory witnesses = diveLog.getAttestations(someDiveId);
```

## License

MIT (implementation) / CC0 (standard specification)
