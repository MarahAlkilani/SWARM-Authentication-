# SwarmAuth: A Secure Authentication Framework for Drone Swarm Communication

![MATLAB](https://img.shields.io/badge/MATLAB-R2026a-blue)
![Security](https://img.shields.io/badge/Security-HMAC--SHA256-red)
![Course](https://img.shields.io/badge/Course-Authentication_&_Security_Models-brightgreen)

## Overview
**SwarmAuth** is a lightweight authentication framework designed for resource-constrained Unmanned Aerial Vehicle (UAV) swarms. Developed in **MATLAB**, this simulation models a 10-node star topology (1 Command & Control Leader, 9 Tactical Wingmen) operating in hostile environments. 

The framework utilizes a fast, symmetric-key challenge-response protocol backed by **HMAC-SHA256** to establish mutual trust without the heavy computational overhead of traditional PKI certificates. 

## Academic Context
* **Institution:** King Abdullah II School for Information Technology, The University of Jordan
* **Course:** Authentication and Security Models (1911461)
* **Team:** Marah Alkilani, Tasnim Abuayyash, Rana Shalout, Leen Naqrash
* **Instructor:** Dr. Oraib Abu-Alganam

## Core Defenses
This simulation actively defends against and logs three specific cyber threats:
1. **Unauthorized Node Injection:** Instantly drops connection requests from unregistered drone IDs.
2. **Replay Attacks:** Enforces strict UTC-synchronized timestamp windows to reject captured, delayed packets.
3. **Impersonation Attacks:** Validates cryptographically signed HMAC responses via mutual authentication to prove identity without exposing the Pre-Shared Key (PSK).

## Repository Files
* `main_simulation.m` - The primary testbench script that runs the swarm scenarios and handles runtime identity initialization.
* `LeaderDrone.m` - Object-oriented class for the C2 Node managing the registry, issuing challenges, and verifying responses.
* `WingmanDrone.m` - Object-oriented class for Tactical Wingmen requesting access and computing cryptographic proofs.
* `compute_hmac.m` - Cryptographic engine utilizing the Java Cryptography Extension (JCE) for high-speed hashing.
* `aes_encrypt.m` & `aes_decrypt.m` - AES-256 (ECB mode) modules for secure payload encryption demonstration.

## How to Run
1. Clone the repository to your local machine.
2. Open MATLAB and set the repository folder as your Current Folder.
3. Open `main_simulation.m` and click **Run** (or type `main_simulation` in the Command Window).
4. Observe the terminal output demonstrating legitimate mutual authentication, P2P encryption, blocked node injection, and replay attack mitigation.
