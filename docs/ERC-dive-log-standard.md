---
eip:
title: On-Chain Dive Log Standard
description: A standard interface for storing and retrieving dive logs on EVM-compatible blockchains.
author: Brad Myrick (github.com/BradMyrick)
discussions-to: https://github.com/kodr-pro/DiveChain/discussions
status: Draft
type: Standards Track
category: ERC
created: 2026-05-03
requires: 165
---

## Abstract

This proposal defines a standard for storing, retrieving, and verifying dive log data on EVM-compatible blockchains. The standard specifies a two-contract architecture: a registry (factory) that manages diver identity and deploys per-diver log book contracts, and individual log book contracts that store immutable dive records.

The data model is derived from U.S. military diving log standards — DD Form 2544 (U.S. Navy Diving Log) and ENG Form 4615 (U.S. Army Corps of Engineers Dive Log) — providing a comprehensive schema that covers commercial, military, scientific, and recreational diving operations.

## Motivation

Dive logs are safety-critical records. They track decompression history, demonstrate qualifications, and provide evidence of experience. Current storage methods are fragile:

- **Paper logbooks** are lost, damaged by water, or destroyed.
- **Centralized applications** shut down when companies fail, taking data with them.
- **Institutional databases** disappear when organizations restructure.
- **No interoperability** exists between logging systems. Each app defines its own schema.

A blockchain-based standard solves these problems:

1. **Permanence** — Data survives any single point of failure.
2. **Ownership** — Divers control their own records via wallet keys.
3. **Interoperability** — A single schema that any application can read and write.
4. **Verifiability** — Dive records are cryptographically signed and timestamped.
5. **Portability** — No vendor lock-in. Any compliant interface can read the data.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

### Architecture

The standard defines two contract interfaces:

1. **`IDiveLogRegistry`** — A factory/registry contract deployed once per ecosystem. Maps diver addresses to their log book contracts.
2. **`IDiveLogBook`** — A per-diver contract that stores dive records. Deployed by the registry when a diver registers.

```
                 ┌─────────────────────┐
                 │   DiveLogRegistry   │
                 │   (singleton)       │
                 └──────┬──────────────┘
                        │ registerDiver()
               ┌────────┴────────┐
               ▼                 ▼
    ┌──────────────────┐  ┌──────────────────┐
    │  DiveLogBook     │  │  DiveLogBook     │
    │  (Diver A)       │  │  (Diver B)       │
    └──────────────────┘  └──────────────────┘
```

### Shared Types

All enums and structs used by both interfaces are defined in a shared type library.

#### Enums

##### UnitSystem

```solidity
enum UnitSystem { Imperial, Metric }
```

##### DiveMode

```solidity
enum DiveMode { SSA, SCUBA }
```

- `SSA` — Surface Supplied Air (surface-supplied diving)
- `SCUBA` — Self-Contained Underwater Breathing Apparatus

##### BreathingGas

```solidity
enum BreathingGas { Air, Nitrox, Heliox, Trimix, Oxygen, Mixed }
```

- `Air` — Compressed air (21% O₂ / 79% N₂)
- `Nitrox` — Enriched air nitrox (EANx, >21% O₂)
- `Heliox` — Helium-oxygen mixture
- `Trimix` — Helium-nitrogen-oxygen mixture
- `Oxygen` — Pure or near-pure oxygen (closed circuit)
- `Mixed` — Other or multiple gas switches during dive

##### BiologicalSex

```solidity
enum BiologicalSex { Male, Female, Unspecified }
```

##### DivePurpose

```solidity
enum DivePurpose {
    Training,        // Training or qualification dive
    Inspection,      // Underwater inspection
    Repair,          // Ship husbandry / repair
    Search,          // Search operations
    Salvage,         // Salvage operations
    Recovery,        // Object recovery
    Construction,    // Underwater construction
    Research,        // Scientific research
    EOD,             // Explosive ordnance disposal
    Security,        // Security swim
    Photographic,    // Underwater photography / documentation
    Recreational,    // Recreational dive
    Other            // Purpose not listed above (use remarks for details)
}
```

##### SuitType

```solidity
enum SuitType { Wet, Dry, HotWater, Swim }
```

- `Wet` — Wet suit
- `Dry` — Dry suit
- `HotWater` — Hot water suit (surface-supplied)
- `Swim` — Swimsuit / no thermal protection

##### DecompressionType

```solidity
enum DecompressionType {
    NoneDecomp,            // No decompression required
    Standard,              // Standard air decompression
    SurfaceDecompO2,       // Surface decompression on oxygen
    SurfaceDecompAir,      // Surface decompression on air
    Saturation,            // Saturation diving
    Repetitive,            // Repetitive dive
    ExceptionalExposure    // Exceptional exposure dive
}
```

### Data Structures

Every dive record and every diver profile MUST declare a unit system. Consumers MUST interpret numeric fields according to the declared unit system:

| Field | Imperial | Metric |
|-------|----------|--------|
| Temperature | Degrees Fahrenheit (°F) | Degrees Celsius (°C) |
| Depth | Feet of Seawater (FSW) | Meters of Seawater (MSW) |
| Height | Inches | Centimeters |
| Weight | Pounds (lbs) | Kilograms (kg) |
| Pressure | PSI | Bar |
| Current | Knots | Knots |

Divers MAY log individual dives in a different unit system than their profile. Each dive record carries its own `UnitSystem` field.

#### DiverProfile

```solidity
struct DiverProfile {
    string name;         // Diver's full name (Last, First, Middle Initial)
    uint8 age;           // Age at time of last profile update
    uint16 height;       // Height (unit per profile's UnitSystem)
    uint16 weight;       // Weight (unit per profile's UnitSystem)
    BiologicalSex sex;   // Biological sex
    UnitSystem units;    // Default unit system for this diver
}
```

**Note:** The `age` field represents the diver's age at the time of the last profile update. It does not automatically track current age. Consumers SHOULD treat this value as "age at time of last `updateProfile()` call."

#### DiveData

Core dive parameters. Every field is REQUIRED unless otherwise noted.

```solidity
struct DiveData {
    uint32 leaveSurfaceTime;     // Unix timestamp — diver descends from surface
    uint32 leaveBottomTime;      // Unix timestamp — diver leaves bottom
    uint32 reachSurfaceTime;     // Unix timestamp — diver reaches surface
    uint32 bottomTimeMinutes;    // Total bottom time in minutes
    int32 maxDepth;              // Maximum depth attained (positive = below surface)
    int32 averageDepth;          // Average depth (OPTIONAL, 0 = not recorded)
    DiveMode mode;               // Dive mode
    DivePurpose purpose;         // Purpose of the dive
    SuitType suit;               // Exposure suit type
}
```

**Constraints:**
- `maxDepth` MUST be greater than 0.
- `bottomTimeMinutes` MUST be greater than 0.
- `leaveSurfaceTime`, `leaveBottomTime`, `reachSurfaceTime` SHOULD be monotonically increasing.

#### Environment

Environmental conditions at the dive site.

```solidity
struct Environment {
    int32 airTemp;               // Air temperature (unit per dive's UnitSystem)
    int32 waterTemp;             // Water temperature (unit per dive's UnitSystem)
    int16 currentKnots;          // Current speed in knots (unit-system-independent)
    string location;             // Human-readable dive location
    string bottomType;           // Bottom composition (e.g., "Mud", "Coral", "Concrete")
    string weatherConditions;    // Weather description (e.g., "Clear", "Overcast, Rain")
}
```

All environment fields are OPTIONAL. Empty strings or zero values indicate not recorded.

#### Decompression

Decompression data for the dive.

```solidity
struct Decompression {
    DecompressionType decompType;              // Decompression method used
    uint32 totalDecompTimeMinutes;             // Total decompression time
    int32 maxDepthAttained;                    // Deepest depth reached during deco (OPTIONAL)
    bytes32 tableSchedule;                     // Table/schedule identifier (e.g., "USN 9-7")
    bytes1 repetitiveGroup;                    // Repetitive group designator (ASCII letter)
    uint32 surfaceIntervalMinutes;             // Surface interval for repetitive dives
    bytes1 newRepetitiveGroup;                 // New repetitive group after surface interval
}
```

For no-decompression dives, `decompType` SHOULD be set to `NoneDecomp` and time fields to 0.

#### GasData

Breathing gas information.

```solidity
struct GasData {
    BreathingGas gasType;        // Primary breathing gas type
    uint16 o2Percent;            // Oxygen percentage (0-100)
    uint16 hePercent;            // Helium percentage (0-100)
    uint16 n2Percent;            // Nitrogen percentage (0-100, or 0 for closed circuit)
    uint32 cylinderPressureIn;   // Cylinder pressure at start of dive
    uint32 cylinderPressureOut;  // Cylinder pressure at end of dive
    uint32 gasConsumed;          // Total gas consumed
    uint32 bailoutPressure;      // Bailout bottle pressure (OPTIONAL, 0 = N/A)
}
```

Pressure fields store values in PSI when `UnitSystem` is `Imperial`, and in Bar when `UnitSystem` is `Metric`. Consumers MUST interpret pressure values according to the dive's declared `UnitSystem`.

#### DiveLog

The complete dive record, assembled from the above structures:

```solidity
struct DiveLog {
    uint256 id;                  // Sequential dive ID within the log book
    uint64 diveDate;             // Unix timestamp of dive date
    UnitSystem units;            // Unit system for this dive's numeric fields
    DiveData data;               // Core dive parameters
    Environment env;             // Environmental conditions
    Decompression decomp;        // Decompression data
    GasData gas;                 // Breathing gas data
    string remarks;              // Free-text remarks, observations, work accomplished
}
```

### Contract Interfaces

#### IDiveLogRegistry

```solidity
interface IDiveLogRegistry is IERC165 {
    event DiverRegistered(address indexed diver, address indexed logBook, uint256 diverId);

    error AlreadyRegistered();
    error NotRegistered();
    error EmptyName();

    function registerDiver(
        string calldata name,
        uint8 age,
        uint16 height,
        uint16 weight,
        BiologicalSex sex,
        UnitSystem units
    ) external returns (address logBook);

    function getLogBook(address diver) external view returns (address);
    function getMyLogBook() external view returns (address);
    function isRegistered(address diver) external view returns (bool);
    function totalDivers() external view returns (uint256);
}
```

**Requirements:**
- `registerDiver` MUST deploy a new `IDiveLogBook` contract with the caller as owner.
- `registerDiver` MUST revert with `AlreadyRegistered` if the caller already has a log book.
- `registerDiver` MUST revert with `EmptyName` if the name string is empty.
- Each address MAY register exactly one log book.
- The registry MUST emit `DiverRegistered` on successful registration.
- The registry MUST implement ERC-165 interface detection and return `true` for the `IDiveLogRegistry` interface ID.

**Enumeration (OPTIONAL):**

Implementations MAY provide additional query functions for log book discovery and pagination:

```solidity
function getAllLogBooks() external view returns (address[] memory);
function getLogBookPage(uint256 offset, uint256 limit) external view returns (address[] memory);
```

These functions are not part of the core interface but are RECOMMENDED for implementations that need to enumerate registered divers.

#### IDiveLogBook

```solidity
interface IDiveLogBook is IERC165 {
    event DiveLogged(uint256 indexed diveId, uint64 indexed diveDate);
    event ProfileUpdated();

    error NotOwner();
    error InvalidDepth();
    error InvalidTimes();
    error DiveNotFound(uint256 diveId);
    error ArrayLengthMismatch();

    function logDive(
        uint64 diveDate,
        UnitSystem units,
        DiveData calldata data,
        Environment calldata env,
        Decompression calldata decomp,
        GasData calldata gas,
        string calldata remarks
    ) external returns (uint256 diveId);

    function batchLogDives(
        uint64[] calldata diveDates,
        UnitSystem[] calldata units,
        DiveData[] calldata dataArr,
        Environment[] calldata envArr,
        Decompression[] calldata decompArr,
        GasData[] calldata gasArr,
        string[] calldata remarksArr
    ) external returns (uint256[] memory diveIds);

    function getDive(uint256 diveId) external view returns (DiveLog memory);
    function getDivesByDate(uint64 date) external view returns (uint256[] memory);
    function getMultipleDives(uint256[] calldata diveIds) external view returns (DiveLog[] memory);
    function getAllDiveIds() external view returns (uint256[] memory);
    function getDiveCount() external view returns (uint256);

    function profile() external view returns (DiverProfile memory);
    function updateProfile(
        string calldata name,
        uint8 age,
        uint16 height,
        uint16 weight,
        BiologicalSex sex,
        UnitSystem units
    ) external;
}
```

**Requirements:**
- `logDive` and `batchLogDives` MUST only be callable by the contract owner.
- `logDive` MUST revert with `InvalidDepth` if `maxDepth <= 0`.
- `logDive` MUST revert with `InvalidTimes` if `bottomTimeMinutes == 0`.
- `getDive` MUST revert with `DiveNotFound` for invalid dive IDs (zero or exceeding dive count).
- `getMultipleDives` MUST revert with `DiveNotFound` if any requested ID is invalid.
- Dive IDs MUST be sequential, starting at 1.
- Dive logs MUST be append-only. No deletion or modification of existing records.
- `updateProfile` MUST only be callable by the contract owner.
- Read functions MUST be accessible by any address.
- `profile` MUST return a `DiverProfile` memory struct.
- The contract MUST implement ERC-165 interface detection and return `true` for the `IDiveLogBook` interface ID.

**`batchLogDives` Requirements:**
- `batchLogDives` MUST revert with `ArrayLengthMismatch` if input array lengths do not all match.
- `batchLogDives` MUST validate each dive identically to `logDive` (depth > 0, bottom time > 0).
- `batchLogDives` MUST revert the entire batch if any single dive is invalid. No partial writes.
- `batchLogDives` MUST emit one `DiveLogged` event per successfully logged dive.

### Source Standards

The data schema in this EIP is derived from the following U.S. military dive logging standards:

#### DD Form 2544 — U.S. Navy Diving Log (Feb 2025)

Filed with the Naval Safety Center (CODE 223). Covers:

- **Part A — Diver Data:** Name, SSN, age, height, weight, sex, service, NOBC/NEC
- **Part B — Environment, Equipment, and Dive History:** Air/water temp, dive location, dive platform, purpose, diving apparatus, type of dress, breathing gas mixtures, gas source, depth, bottom time, surface times
- **Part C — Decompression Data:** Decompression schedule type, surface interval, decompression location, total decompression time
- **Part D — Saturation Dive Data:** Storage depth, compression rate, chamber atmospheric O₂ partial pressure, excursion depths

Authority: SECNAVINST 5100.10L; EO 9397

#### ENG Form 4615 — U.S. Army Corps of Engineers Dive Log (Feb 2021)

Per ER 385-1-86. Covers:

- Diver and standby diver identification and fitness
- Date, time, and location of dive
- Weather conditions (clear, cloudy, rain, snow, sleet, freezing/ice, wind, hot/humid)
- Dive mode (SSA/SCUBA), air supply source, backup supply
- Temperatures (air and water), bottom type, current
- Per-dive records (up to 6 per form): bailout pressure, time in/out, bottom time, residual nitrogen time, total bottom time, depth, sea level equivalent depth, table and schedule, repetitive groups, surface interval, air consumption
- Work accomplished, remarks, decompression stops
- Signatures: diver, dive supervisor, reviewer

### Rationale

#### Why a two-contract architecture?

Per-diver contracts provide natural isolation and ownership. Each diver's data lives in their own contract with their own access control. The registry provides discovery without coupling storage.

#### Why structs instead of individual fields?

Grouping related data into structs (`DiveData`, `Environment`, `Decompression`, `GasData`) reduces the number of function parameters, improves readability, and maps cleanly to the military source forms which group fields into sections.

#### Why support both Imperial and Metric?

The U.S. military diving community operates in Imperial units (FSW, PSI, °F). International and scientific diving communities use Metric (MSW, bar, °C). Supporting both maximizes adoption. Per-dive unit declarations allow a single diver to mix conventions across dives without ambiguity.

#### Why unit-agnostic pressure field names?

Previous versions used `airInPsi`/`airOutPsi`/`airUsedPsi`, which implied a specific unit. The renamed fields (`cylinderPressureIn`, `cylinderPressureOut`, `gasConsumed`) allow the same struct to store values in either PSI (Imperial) or Bar (Metric) based on the dive's declared `UnitSystem`, avoiding confusion.

#### Why `BiologicalSex` enum instead of a boolean?

A boolean (`isMale`) is ambiguous in its encoding and does not accommodate divers who prefer not to disclose biological sex. The `BiologicalSex` enum (`Male`, `Female`, `Unspecified`) is clearer in its semantics and forward-compatible.

#### Why not store all data on-chain as events?

Events are not reliably accessible from smart contracts and may be pruned by nodes. Struct storage in contract state ensures data is always retrievable by any on-chain or off-chain consumer.

#### Why append-only?

Dive logs are safety records. Modifying or deleting a dive log after the fact undermines their value as evidence of experience and decompression history. The append-only design matches the legal and safety nature of these records.

#### Why immutable implementations?

Dive log contracts store safety-critical, immutable records. If an implementation were upgradeable (e.g., via a proxy pattern), the upgrade authority could potentially modify or delete dive logs, undermining the append-only guarantee. Implementations SHOULD be deployed as immutable contracts. If upgradeability is required, implementations MUST preserve the append-only invariant and MUST NOT expose functions to modify or delete existing dive records.

### Backwards Compatibility

This EIP does not conflict with any existing ERC standards. New contracts implementing this standard MUST also implement ERC-165 (interface detection) and return `true` for both `IERC165` and the respective interface ID (`IDiveLogBook` or `IDiveLogRegistry`).

### Security Considerations

- **Access control** — Only the designated owner may write to a `DiveLogBook`. The owner is set at construction by the registry and is immutable.
- **No sensitive data** — Dive logs do not contain personally identifying information beyond what a diver chooses to include in their name string. Social security numbers, military IDs, and other sensitive identifiers are NOT part of this standard.
- **Append-only** — Immutability protects against retroactive modification of safety-critical records.
- **Gas costs** — Storing a full `DiveLog` struct requires significant gas. Consumers should be aware of gas costs and use `batchLogDives` for efficiency when logging multiple dives.
- **Immutable contracts** — Implementations SHOULD be deployed without proxy upgradeability to guarantee the append-only property. If proxies are used, the implementation MUST not contain functions that modify or delete existing dive records.

### Gas Benchmarks

Approximate gas costs from the reference implementation (Solidity 0.8.33, optimizer enabled, 200 runs):

| Operation | Gas (approx) |
|-----------|-------------|
| `DiveLogRegistry` deployment | ~3,320,000 |
| `DiveLogBook` deployment (via `registerDiver`) | included above |
| `registerDiver` | ~2,706,000 |
| `logDive` (1 dive) | ~349,000 |
| `batchLogDives` (1 dive) | ~43,000 (additional dives: ~350,000 each) |
| `batchLogDives` (3 dives) | ~1,027,000 |
| `getDive` (view) | ~34,000 |
| `getMultipleDives` (2 dives, view) | ~51,000 |
| `getDivesByDate` (view) | ~5,200 |
| `getAllDiveIds` (view) | ~3,700 |
| `profile` (view) | ~5,800 |
| `updateProfile` | ~30,000 |
| `supportsInterface` (view) | ~270 |

### Reference Implementation

See `src/DiveLogRegistry.sol`, `src/DiveLogBook.sol`, and `src/interfaces/` in this repository.

The specification text in this document is licensed under CC0. The reference implementation code is licensed under MIT.

### Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
