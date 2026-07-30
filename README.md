# Antarctic Ice Melt Emulator (AIME)

The Antarctic Ice Melt Emulator (AIME) is a computationally efficient emulator of ocean-driven Antarctic ice-sheet mass loss designed for coupled Earth system model simulations. It provides an interactive representation of the feedback between Antarctic ice-sheet melting, freshwater input to the Southern Ocean, and climate, without requiring a fully dynamic ice-sheet model.

## Overview

AIME simulates Antarctic freshwater release by linking subsurface ocean temperatures over the Antarctic continental shelf to regional basal melting of ice shelves. The resulting ice-sheet response is delayed using linear response functions, allowing the emulator to capture the long response times of the Antarctic Ice Sheet. The freshwater released to the ocean is then fed back into the coupled climate model, enabling two-way interactions between the ocean, atmosphere, sea ice, and ice sheet.

The current implementation has been developed for the EC-Earth3 Earth system model but is sufficiently modular to be adapted to other ocean or climate models.

## Method

Antarctica is divided into five regions:

- East Antarctica
- Ross Sea
- Amundsen Sea Embayment
- Antarctic Peninsula
- Weddell Sea

For each region, the emulator performs the following steps every model year:

1. **Ocean forcing**

   Annual mean ocean temperatures are averaged over the continental shelf south of the 1000 m isobath between 200 and 700 m depth.

2. **Basal melt calculation**

   Regional basal melt is calculated from quadratic parameterizations relating ocean thermal forcing to basal melt rates. The regional basal melt sensitivities are derived from simulations with the LADDIE basal melt model.

3. **Ice-sheet response**

   Changes in basal melt are converted into total ice mass loss using regional linear response functions derived from dynamic ice-sheet simulations. These response functions account for the delayed adjustment of the Antarctic Ice Sheet to changes in basal melting.

4. **Freshwater partitioning**

   Total freshwater release is partitioned into basal-melt and calving components using prescribed region-specific fractions based on observational estimates. Although these fractions remain constant for each region, the Antarctic-wide partition between basal melt and calving evolves over time as the relative contribution of each region changes.

5. **Application to the ocean model**

   The two freshwater components are applied differently:

   - **Basal melt:** released locally near ice shelves between 200 and 700 m depth (or at the seabed where shallower), together with the associated heat flux required to melt the ice.
   - **Calving:** distributed over the Southern Ocean surface to represent iceberg drift and melting away from the Antarctic coast.

## Coupling

When coupled to EC-Earth3, AIME replaces the standard prescribed Antarctic freshwater anomaly with an interactive freshwater source.

The coupling proceeds as follows:

```text
Shelf-ocean temperature
          │
          ▼
  Basal melt parameterization
          │
          ▼
 Regional basal melt
          │
          ▼
 Linear response functions
          │
          ▼
 Delayed ice mass loss
          │
          ▼
 Freshwater partitioning
          │
          ▼
 Basal melt + Calving fluxes
          │
          ▼
      Ocean model
          │
          ▼
 Updated shelf temperatures
```

This two-way coupling allows ocean conditions to influence Antarctic ice loss, while the resulting freshwater and heat fluxes modify ocean circulation, stratification, sea ice, and climate.

## Features

- Interactive Antarctic freshwater forcing
- Regionally varying basal melt parameterizations
- Delayed ice-sheet response using linear response functions
- Separate treatment of basal melt and iceberg calving
- Computationally efficient alternative to dynamic ice-sheet coupling
- Suitable for climate warming scenarios only

## Limitations

AIME is an emulator and therefore does not explicitly simulate:

- Ice-sheet dynamics
- Ice-shelf cavity circulation
- Grounding-line migration
- Iceberg trajectories
- Changes in ice-sheet geometry

Instead, these processes are represented through parameterizations and linear response functions derived from higher-complexity ice-sheet and ocean models.

## Citation

If you use AIME in scientific work, please cite:

Title: Antarctic meltwater induces competing climate feedbacks in an Earth system model coupled to an Antarctic ice melt emulator
Authors: Eveline C. van der Linden et al.
Journal: Earth System Dynamics
[Add link to paper when published]
