# DPL (WIP)

[![Build Status](https://github.com/souma4/DPL.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/souma4/DPL.jl/actions/workflows/CI.yml?query=branch%3Amain)

**Currently heavily work in progress, do not use**

## Overview

Implementation of [openDendro's](https://opendendro.org) `dpl` ecosystem in native Julia. 

Builds tree-ring and paleoecological analyses such as detrending, chronology building, crossdating, and superposed epoch analysis.

## Phases of development

### Core functionality

1. Build core datatypes and basic methods from `dpl` using the Tables.jl interface and simple dependencies

2. Fully "Juliarize" the code for efficiency and extendability

3. Build extensions for plotting in Makie

### Interesting goals

* attach functionality from existing packages built on top of the `dpl` ecosystems from R and Python

* attach georeferencing for spatial analyses.
