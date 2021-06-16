```@meta
CurrentModule = Sugars
```

# Sugars

This module provides the the functionalities for building and manipulating
sugars.

```yml
amylose:
  rules:
    A:
      - {p: 1.0, production: [A,α,A]}
  variables:
    A: resources/Sugars/yml/glu14.yml
  defop: α
  operators:
    α:
      residue1: C1
      residue2: O4
      presets:
        O4:
          θ:  2.2165681500327987  # 127 deg
          ϕ: -1.5832230710690962  # -90.712 deg
          b:  1.43
        C4:
          θ:  1.7453292519943295  # 100 deg
          ϕ: -1.8059794435011325  # -103.475 deg
      offsets:
        H4: 0
```

## load stuff

```@docs
grammar
```
