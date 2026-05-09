# Dive Data Standard — Field Reference

This document provides a complete field-level reference for the Divechain on-chain dive log format, with source mappings to the originating military forms.

## Source Forms

| Form | Issuing Authority | Date | Reference |
|------|-------------------|------|-----------|
| DD Form 2544 | U.S. Navy / Naval Safety Center | Feb 2025 | SECNAVINST 5100.10L |
| ENG Form 4615 | U.S. Army Corps of Engineers | Feb 2021 | ER 385-1-86 |

These forms represent the most comprehensive dive logging standards in existence, used by U.S. Navy, Army, Marine Corps, Coast Guard, and civilian diving operations worldwide.

---

## Unit Systems

The standard supports two unit systems. Each dive record declares its own unit system, independent of the diver's profile default.

### Imperial

Used by U.S. military diving operations. All depth measurements are Feet of Seawater (FSW).

| Measurement | Unit | Solidity Type | Notes |
|-------------|------|---------------|-------|
| Depth | Feet of Seawater (FSW) | `int32` | Always positive below surface |
| Temperature | Degrees Fahrenheit (°F) | `int32` | Signed — can be negative |
| Pressure | Pounds per Square Inch (PSI) | `uint32` | Unsigned — always positive |
| Height | Inches | `uint16` | |
| Weight | Pounds (lbs) | `uint16` | |
| Current | Knots | `int16` | |

### Metric

Used by international and scientific diving communities. Depth in Meters of Seawater (MSW).

| Measurement | Unit | Solidity Type | Notes |
|-------------|------|---------------|-------|
| Depth | Meters of Seawater (MSW) | `int32` | Always positive below surface |
| Temperature | Degrees Celsius (°C) | `int32` | Signed — can be negative |
| Pressure | Bar | `uint32` | Unsigned — always positive |
| Height | Centimeters | `uint16` | |
| Weight | Kilograms (kg) | `uint16` | |
| Current | Knots | `int16` | Shared across both systems |

### Conversion Reference

| From Imperial | To Metric | Formula |
|---------------|-----------|---------|
| FSW | MSW | FSW × 0.3048 |
| °F | °C | (°F − 32) × 5/9 |
| PSI | Bar | PSI ÷ 14.5038 |
| Inches | cm | in × 2.54 |
| lbs | kg | lbs × 0.453592 |

---

## Diver Profile

Set at registration, updatable by the owner.

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `name` | `string` | DD2544 Block 5, ENG4615 Block 1 | Full name in "Last, First, Middle Initial" format |
| `age` | `uint8` | DD2544 Block 6 | Age at time of last profile update. Range: 0–255. Consumers SHOULD treat this as "age at time of last `updateProfile()` call" |
| `height` | `uint16` | DD2544 Block 7 | Inches (Imperial) or centimeters (Metric) |
| `weight` | `uint16` | DD2544 Block 8 | Pounds (Imperial) or kilograms (Metric) |
| `sex` | `BiologicalSex` | DD2544 Block 9 | `Male` (0), `Female` (1), or `Unspecified` (2) |
| `units` | `UnitSystem` | — | Default unit system for display. Individual dives may override |

### BiologicalSex Enum

| Value | Name | Description |
|-------|------|-------------|
| 0 | `Male` | Male |
| 1 | `Female` | Female |
| 2 | `Unspecified` | Not disclosed |

---

## Dive Data (DiveData struct)

Core dive parameters. Maps to DD2544 Part B and ENG4615 Dive Records.

| Field | Type | Source (DD2544) | Source (ENG4615) | Description |
|-------|------|-----------------|------------------|-------------|
| `leaveSurfaceTime` | `uint32` | Block 28 "Leave Surface" | Block 17 "Time In" | Unix timestamp when diver begins descent |
| `leaveBottomTime` | `uint32` | Block 29 "Max Depth of Dive" context | Block 18 "Leave Bottom" | Unix timestamp when diver begins ascent |
| `reachSurfaceTime` | `uint32` | Block 31 "Reach Surface" | Block 19 "Time Out" | Unix timestamp when diver surfaces |
| `bottomTimeMinutes` | `uint32` | Block 30 "Bottom Time Used" | Block 20 "Actual Bottom Time" | Time from leaving surface to leaving bottom, in whole minutes |
| `maxDepth` | `int32` | Block 29 "Max Depth of Dive" | Block 23 "Dive Depth" | Maximum depth attained. MUST be > 0. In FSW or MSW per unit system |
| `averageDepth` | `int32` | — | — | Average depth if recorded. 0 = not recorded |
| `mode` | `DiveMode` | Block 23 "Diving Apparatus" | Block 12 "Dive Mode" | `SSA` (0) or `SCUBA` (1) |
| `purpose` | `DivePurpose` | Block 20 "Purpose of Dive" | Block 32 "Work Accomplished" | See DivePurpose enum below |
| `suit` | `SuitType` | Block 24 "Type Dress" | Block 9 (implied) | Exposure suit type |

### DiveMode Enum

| Value | Name | DD2544 Mapping | Description |
|-------|------|----------------|-------------|
| 0 | `SSA` | MK-1, MK-12, Superlite variants | Surface Supplied Air — gas delivered from surface via umbilical |
| 1 | `SCUBA` | SCUBA Open, LAR-5, MK-15, MK-16 | Self-Contained Underwater Breathing Apparatus — carried gas supply |

### DivePurpose Enum

| Value | Name | DD2544 Block 20 Code | Description |
|-------|------|----------------------|-------------|
| 0 | `Training` | V — Student | Training dives, qualification, indoctrination |
| 1 | `Inspection` | H — Inspection | Underwater inspection of structures, hulls, pipelines |
| 2 | `Repair` | S — Ships Husbandry/Repair | Underwater repair, maintenance, patching |
| 3 | `Search` | O — Search | Search and survey operations |
| 4 | `Salvage` | N — Salvage | Salvage of vessels, aircraft, or equipment |
| 5 | `Recovery` | K — Recovery | Object recovery operations |
| 6 | `Construction` | W — Underwater Construction Ops | Underwater construction, welding, cutting |
| 7 | `Research` | M — Research | Scientific research, data collection |
| 8 | `EOD` | A — EOD Ops | Explosive ordnance disposal |
| 9 | `Security` | P — Security Swim | Security swims, port security |
| 10 | `Photographic` | — | Underwater photography, video documentation |
| 11 | `Recreational` | — | Recreational/sport diving |
| 12 | `Other` | D — Experimental, Z — None | Purpose not otherwise classified. Use remarks field for details |

### SuitType Enum

| Value | Name | DD2544 Block 24 Code | Description |
|-------|------|----------------------|-------------|
| 0 | `Wet` | W — Wet | Wetsuit, neoprene, partial thermal protection |
| 1 | `Dry` | D — Dry | Dry suit, sealed, full thermal protection |
| 2 | `HotWater` | H — Hot Water | Hot water suit, surface-supplied heated water |
| 3 | `Swim` | S — Swim | Swimsuit only, no thermal protection |

---

## Environment (Environment struct)

Environmental conditions at the dive site. All fields optional — zero values or empty strings indicate "not recorded."

| Field | Type | Source (DD2544) | Source (ENG4615) | Description |
|-------|------|-----------------|------------------|-------------|
| `airTemp` | `int32` | Block 14 "Air Temp" | Block 15 "Air" | Air temperature. °F or °C per unit system. Signed for sub-zero |
| `waterTemp` | `int32` | Block 15 "Water Temp" | Block 15 "Water" | Water temperature at dive site. °F or °C per unit system |
| `currentKnots` | `int16` | — | Block 10 "Current" | Water current speed in knots (unit-system-independent) |
| `location` | `string` | Block 16 "Dive Location" | Block 6 "Location of Dive" | Human-readable location name |
| `bottomType` | `string` | — | Block 11 "Bottom Type" | Bottom composition: "Mud", "Sand", "Coral", "Rock", "Concrete", "Silt", etc. |
| `weatherConditions` | `string` | — | Block 8 "Weather Conditions" | Weather description. ENG4615 options: Clear, Cloudy, Drizzle, Rain, Snow, Sleet, Freezing/Ice, Hot/Humid, Wind |

---

## Decompression (Decompression struct)

Decompression planning and execution data. Maps to DD2544 Part C and ENG4615 Blocks 25–28.

| Field | Type | Source (DD2544) | Source (ENG4615) | Description |
|-------|------|-----------------|------------------|-------------|
| `decompType` | `DecompressionType` | Block 34 "Decompression Schedule" | Block 25 "Table and Schedule" | Decompression method used |
| `totalDecompTimeMinutes` | `uint32` | Block 37–38 "Total Decompression Time" | Calculated from stops | Total time spent in decompression, in minutes |
| `maxDepthAttained` | `int32` | Block 29 | Block 23 | Maximum depth reached during the dive. Redundant with DiveData for cross-reference |
| `tableSchedule` | `bytes32` | Block 34 | Block 25 | Decompression table identifier. e.g., "USN Table 9-7", "RNPL", "DCIEM" |
| `repetitiveGroup` | `bytes1` | Block 26 "Repetitive Group" | Block 26 | Repetitive group designator. Single ASCII uppercase letter: A–Z (0x41–0x5A). 0x00 = N/A |
| `surfaceIntervalMinutes` | `uint32` | Block 35 "Surface Interval" | Block 27 "Surface Interval" | Surface interval between repetitive dives, in minutes. 0 = first dive or not applicable |
| `newRepetitiveGroup` | `bytes1` | Block 35 (derived) | Block 28 "New Repetitive Group" | Repetitive group after surface interval. Single ASCII letter. 0x00 = N/A |

### DecompressionType Enum

| Value | Name | DD2544 Block 34 Code | Description |
|-------|------|----------------------|-------------|
| 0 | `NoneDecomp` | A — No Decompression | No decompression stops required |
| 1 | `Standard` | B — Standard Air | Standard air decompression schedule |
| 2 | `SurfaceDecompO2` | K — Surface Decompression/O2 | Surface decompression using oxygen |
| 3 | `SurfaceDecompAir` | L — Surface Decompression/Air | Surface decompression using air |
| 4 | `Saturation` | J — Saturation | Saturation diving decompression |
| 5 | `Repetitive` | C — Repet Air | Repetitive dive decompression |
| 6 | `ExceptionalExposure` | D — Exceptional Exposure/Air | Exceptional exposure decompression |

---

## Gas Data (GasData struct)

Breathing gas composition and consumption. Maps to DD2544 Block 26 and ENG4615 Blocks 29–31.

| Field | Type | Source (DD2544) | Source (ENG4615) | Description |
|-------|------|-----------------|------------------|-------------|
| `gasType` | `BreathingGas` | Block 23/26 (implied) | Block 13 (implied) | Primary breathing gas classification |
| `o2Percent` | `uint16` | Block 26 "O2" | — | Oxygen fraction, 0–100. Air = 21, Nitrox32 = 32 |
| `hePercent` | `uint16` | Block 26 "He" | — | Helium fraction, 0–100. 0 for air/nitrox |
| `n2Percent` | `uint16` | Block 26 "N2" | — | Nitrogen fraction, 0–100. Air = 79. 0 for closed circuit O2 |
| `cylinderPressureIn` | `uint32` | — | Block 29 "Air In" | Cylinder pressure at start of dive. PSI (Imperial) or Bar (Metric) per dive's UnitSystem |
| `cylinderPressureOut` | `uint32` | — | Block 30 "Air Out" | Cylinder pressure at end of dive. Same unit convention |
| `gasConsumed` | `uint32` | — | Block 31 "Total Air Used" | Gas consumed = cylinderPressureIn − cylinderPressureOut. Stored directly for gas savings |
| `bailoutPressure` | `uint32` | — | Block 16 "Bailout Bottle Pressure" | Emergency bailout cylinder pressure. 0 = not applicable or not recorded. Same unit convention |

### BreathingGas Enum

| Value | Name | Typical Mix | DD2544 Apparatus | Description |
|-------|------|-------------|-------------------|-------------|
| 0 | `Air` | 21% O₂ / 79% N₂ | SCUBA Open, SSA | Compressed atmospheric air |
| 1 | `Nitrox` | 22–40% O₂ / balance N₂ | SCUBA with EANx | Enriched Air Nitrox (EANx) |
| 2 | `Heliox` | Variable O₂ / balance He | MK-15, MK-16 | Helium-oxygen mixture |
| 3 | `Trimix` | Variable O₂ / He / N₂ | Custom | Three-gas mixture for deep diving |
| 4 | `Oxygen` | ~100% O₂ | LAR-5, O₂ UBA | Pure or near-pure oxygen (closed circuit) |
| 5 | `Mixed` | Variable | Multi-gas dives | Multiple gas switches or non-standard mixtures |

---

## Dive Log (DiveLog struct)

Top-level container assembled from the above structures.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `uint256` | Sequential identifier, auto-incremented starting at 1 |
| `diveDate` | `uint64` | Unix timestamp (seconds since epoch) of the dive date. Time component should be 00:00:00 UTC for date-only precision |
| `units` | `UnitSystem` | Unit system for this specific dive's numeric fields |
| `data` | `DiveData` | Core dive parameters |
| `env` | `Environment` | Environmental conditions |
| `decomp` | `Decompression` | Decompression data |
| `gas` | `GasData` | Breathing gas data |
| `remarks` | `string` | Free-text field for observations, work accomplished, decompression stop details, underwater conditions. Maps to DD2544 "Comments" and ENG4615 Block 32 |

---

## Void Info (VoidInfo struct)

Corrective ledger data for the Void/Supersede mechanism. Dive logs are never edited or deleted — instead, they are voided with an optional superseding dive reference.

| Field | Type | Description |
|-------|------|-------------|
| `isVoided` | `bool` | Whether this dive has been voided |
| `supersededById` | `uint256` | ID of the dive that supersedes this one. 0 = voided without replacement |
| `voidedBy` | `address` | Address that initiated the void operation |
| `voidedAt` | `uint64` | Unix timestamp when the dive was voided |
| `reason` | `string` | Human-readable explanation for the void (e.g., "Incorrect depth recorded", "Duplicate entry") |

### Void/Supersede Flow

1. Diver logs dive #5 (contains an error)
2. Diver logs corrected dive #6
3. Diver calls `voidDive(5, 6, "Incorrect depth recorded")` — marks #5 as superseded by #6
4. Dive #5 data remains readable via `getDive(5)`, but `isDiveVoided(5)` returns `true`
5. `getVoidInfo(5)` returns the full void record including the reason and link to #6

A dive MAY be voided without a superseding dive (`supersededById == 0`) for cases like duplicate entries.

---

## Attestation (Attestation struct)

Cryptographic buddy/instructor sign-off record. Created when a third party signs the dive data via EIP-712 and the signature is submitted on-chain.

| Field | Type | Description |
|-------|------|-------------|
| `attester` | `address` | Address of the signer (recovered from EIP-712 signature) |
| `attestedAt` | `uint64` | Unix timestamp when the attestation was recorded on-chain |

### EIP-712 Attestation Signing

An attester signs the following EIP-712 typed data:

```
Domain: { name: "DiveLog", version: "1", chainId: <chainId>, verifyingContract: <diveLogAddress> }
Type: Attestation(uint256 diveId, address verifyingContract)
```

This binds the attestation to a specific dive on a specific contract on a specific chain, preventing replay attacks.

---

## Validation Rules

The following invariants MUST hold for any dive log stored on-chain:

1. **Dive ID**: Sequential, starting at 1. Never reused, never modified.
2. **Max depth**: MUST be > 0. A dive with zero or negative depth is invalid.
3. **Bottom time**: MUST be > 0. A dive with zero bottom time is invalid.
4. **Timestamps**: `leaveSurfaceTime` < `leaveBottomTime` < `reachSurfaceTime` (SHOULD, not enforced on-chain for gas efficiency).
5. **Gas percentages**: `o2Percent + hePercent + n2Percent` SHOULD total ≤ 100. Trace gases are omitted.
6. **Repetitive group**: Single ASCII uppercase letter (A–Z), or 0x00 if not applicable.
7. **Append-only**: No dive, once logged, may be deleted or modified. Corrections use the Void/Supersede mechanism.
8. **Ownership**: Only the contract owner (the diver) may log dives, void dives, or update the profile.
9. **Array lengths**: `batchLogDives` MUST receive arrays of equal length or revert.
10. **Void immutability**: A voided dive cannot be un-voided or re-voided.
11. **Supersede validity**: If `supersededById > 0`, it MUST reference an existing dive that is not the dive being voided.
12. **Attestation uniqueness**: Each address MAY attest a given dive exactly once.
13. **Attestation on non-voided dives**: Attestations on voided dives MUST revert.
14. **Signature recovery**: Attestation signatures MUST recover to a valid (non-zero) Ethereum address.

---

## DD Form 2544 Field Mapping (Complete)

For implementors who need to map DD2544 fields to this standard:

| DD2544 Field | Divechain Path | Notes |
|--------------|---------------|-------|
| Block 1 — Dive Date | `DiveLog.diveDate` | Unix timestamp |
| Block 2 — UIC | Not included | Military-specific, privacy concern |
| Block 3 — Activity Name | `Environment.location` | |
| Block 4 — SSN | Not included | Privacy — DO NOT store on-chain |
| Block 5 — Name | `DiverProfile.name` | |
| Block 6 — Age | `DiverProfile.age` | Age at last profile update |
| Block 7 — Height | `DiverProfile.height` | |
| Block 8 — Weight | `DiverProfile.weight` | |
| Block 9 — Sex | `DiverProfile.sex` | `BiologicalSex` enum |
| Block 10 — Service | Not included | Military-specific |
| Block 11 — NOBC/NEC | Not included | Military-specific |
| Block 14 — Air Temp | `Environment.airTemp` | |
| Block 15 — Water Temp | `Environment.waterTemp` | |
| Block 16 — Dive Location | `Environment.location` | |
| Block 17 — Dive Platform | `DiveLog.remarks` | Free text |
| Block 18 — — | — | |
| Block 19–20 — Purpose | `DiveData.purpose` | Enum |
| Block 21 — Dive Platform | `DiveLog.remarks` | A–I codes in remarks |
| Block 23 — Diving Apparatus | `DiveData.mode` + `GasData.gasType` | |
| Block 24 — Type Dress | `DiveData.suit` | Enum |
| Block 25 — Source of Gas Supply | `DiveLog.remarks` | |
| Block 26 — Breathing Gas % | `GasData.o2Percent`, `hePercent`, `n2Percent` | |
| Block 28 — Leave Surface | `DiveData.leaveSurfaceTime` | Unix timestamp |
| Block 29 — Max Depth | `DiveData.maxDepth` | |
| Block 30 — Bottom Time Used | `DiveData.bottomTimeMinutes` | |
| Block 31 — Reach Surface | `DiveData.reachSurfaceTime` | Unix timestamp |
| Block 34 — Decomp Schedule | `Decompression.decompType` | Enum |
| Block 35 — Surface Interval | `Decompression.surfaceIntervalMinutes` | |
| Block 36 — Decomp Location | `DiveLog.remarks` | C/W code in remarks |
| Block 37 — Total Decomp Time (Table) | `Decompression.totalDecompTimeMinutes` | |
| Block 38 — Total Decomp Time (Used) | `Decompression.totalDecompTimeMinutes` | Actual time used |
| Block 42 — Storage Depth | `Decompression.maxDepthAttained` | Saturation only |
| Signature blocks | Not included | On-chain tx signatures serve this purpose |

## ENG Form 4615 Field Mapping (Complete)

| ENG4615 Field | Divechain Path | Notes |
|---------------|---------------|-------|
| Block 1 — Primary Diver | `DiverProfile.name` | |
| Block 1a — Last Dive 24h | `Decompression.surfaceIntervalMinutes` | If < 1440 minutes |
| Block 2 — Fit To Dive | Not included | Attestation, not data |
| Block 3 — Date/Time | `DiveLog.diveDate` | Unix timestamp |
| Block 4 — Standby Diver | `DiveLog.remarks` | Name in remarks |
| Block 4a — Last Dive 24h | Not included | For standby diver |
| Block 5 — Fit To Dive (Standby) | Not included | |
| Block 6 — Location | `Environment.location` | |
| Block 7 — Dive Tender | `DiveLog.remarks` | Name in remarks |
| Block 8 — Weather | `Environment.weatherConditions` | |
| Block 9 — Suit Type | `DiveData.suit` | Enum |
| Block 10 — Current | `Environment.currentKnots` | |
| Block 11 — Bottom Type | `Environment.bottomType` | |
| Block 12 — Dive Mode | `DiveData.mode` | SSA or SCUBA |
| Block 13 — Air Supply | `GasData.gasType` + remarks | |
| Block 14 — Backup | `DiveLog.remarks` | |
| Block 15 — Temperature | `Environment.airTemp`, `waterTemp` | |
| Block 16 — Bailout Pressure | `GasData.bailoutPressure` | |
| Block 17 — Time In | `DiveData.leaveSurfaceTime` | |
| Block 18 — Leave Bottom | `DiveData.leaveBottomTime` | |
| Block 19 — Time Out | `DiveData.reachSurfaceTime` | |
| Block 20 — Actual Bottom Time | `DiveData.bottomTimeMinutes` | |
| Block 21 — Residual Nitrogen Time | `Decompression.surfaceIntervalMinutes` context | |
| Block 22 — Total Bottom Time | `DiveData.bottomTimeMinutes` | Includes RNT if applicable |
| Block 23 — Dive Depth | `DiveData.maxDepth` | |
| Block 24 — Sea Level Equivalent | `Decompression.maxDepthAttained` | Altitude-adjusted depth |
| Block 25 — Table and Schedule | `Decompression.tableSchedule` | |
| Block 26 — Repetitive Group | `Decompression.repetitiveGroup` | |
| Block 27 — Surface Interval | `Decompression.surfaceIntervalMinutes` | |
| Block 28 — New Repetitive Group | `Decompression.newRepetitiveGroup` | |
| Block 29 — Air In | `GasData.cylinderPressureIn` | PSI or Bar per UnitSystem |
| Block 30 — Air Out | `GasData.cylinderPressureOut` | PSI or Bar per UnitSystem |
| Block 31 — Total Air Used | `GasData.gasConsumed` | PSI or Bar per UnitSystem |
| Block 32 — Work/Remarks | `DiveLog.remarks` | |
| Block 33 — Signatures | Not included | On-chain tx serves as signature |

---

## Privacy Considerations

The following fields from the source forms are deliberately **excluded** from the on-chain standard:

| Excluded Field | Source Form | Reason |
|----------------|-------------|--------|
| Social Security Number (SSN) | DD2544 Block 4 | PII — must never be stored on a public blockchain |
| UIC (Unit Identification Code) | DD2544 Block 2 | Military OPSEC |
| Service branch codes | DD2544 Block 10 | Military-specific, not relevant to civilian use |
| NOBC/NEC codes | DD2544 Block 11 | Military-specific |
| Signature blocks | Both forms | On-chain transaction signatures serve the same purpose cryptographically |
| Fit to Dive attestation | ENG4615 Block 2, 5 | Ephemeral medical status, not historical record |

Divers and organizations implementing this standard should never store personally identifiable information (PII) beyond the diver's chosen display name. The blockchain is public and immutable.
