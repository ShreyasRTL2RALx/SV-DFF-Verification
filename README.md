# SV-DFF-Verification

Transaction-based verification of a D Flip-Flop using SystemVerilog with Generator, Driver, Monitor, and Scoreboard architecture.

## Project Overview

This project implements a self-checking verification environment for a D Flip-Flop (DFF) using SystemVerilog. The testbench follows a transaction-based methodology and applies Object-Oriented Programming (OOP) concepts for modular and reusable verification components.

## Concepts Applied

- Classes and Objects
- Randomization (`rand`)
- Deep Copy Mechanism
- Mailboxes (IPC)
- Events and Synchronization
- Virtual Interfaces
- Generator-Driver-Monitor-Scoreboard Architecture
- Fork-Join Parallel Execution
- Self-Checking Testbench Design

## Verification Components

### Transaction
Stores input (`din`) and output (`dout`) data and implements a deep copy mechanism.

### Generator
Generates randomized input stimuli and sends transaction copies to both the driver and scoreboard.

### Driver
Receives transactions from the generator and applies them to the DUT through a virtual interface.

### Monitor
Captures DUT outputs and forwards them to the scoreboard.

### Scoreboard
Compares the expected output with the actual DUT output and reports match or mismatch.

### Environment
Connects all verification components and controls the complete simulation flow.

## Verification Flow

Generator → Driver → D Flip-Flop (DUT) → Monitor → Scoreboard

The generator also sends reference transactions directly to the scoreboard for automatic result comparison.

## Tools Used

- SystemVerilog
- EDA Playground
- GTKWave

## Learning Outcomes

Through this mini-project, I gained practical experience in:

- Building transaction-based verification environments
- Using SystemVerilog OOP concepts
- Implementing inter-process communication using mailboxes and events
- Developing self-checking testbenches
- Understanding the interaction between Generator, Driver, Monitor, and Scoreboard components


