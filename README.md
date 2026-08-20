# SwarmAuth: A Secure Authentication Framework for Drone Swarm Communication

![MATLAB](https://img.shields.io/badge/MATLAB-R2026a-blue.svg)
![Security](https://img.shields.io/badge/Security-AES--GCM%20%7C%20HMAC--SHA256-success.svg)
![Course](https://img.shields.io/badge/Course-Authentication%20and%20Security%20Models-orange.svg)



## 📌 Project Overview
Modern drone swarms rely on continuous wireless communication, making them highly vulnerable to identity-based cyber threats. **SwarmAuth** is a lightweight, secure authentication framework designed specifically for resource-constrained Unmanned Aerial Vehicles (UAVs). 

The framework enforces strict mutual authentication using a symmetric **HMAC-SHA256** challenge-response protocol and secures operational peer-to-peer (P2P) telemetry using **AES-256 in Galois/Counter Mode (GCM)**. Evaluated via a 10-node star topology in MATLAB, SwarmAuth actively defends against Unauthorized Node Injection, Impersonation, Time-Stale Replay Attacks, and Man-in-the-Middle (MITM) tampering.

## 🚀 Core Architecture & Features
* **Strict Mutual Authentication:** A centralized Cluster Head (CH) and connecting Wingmen must mathematically prove their identities using pre-shared keys (PSKs) and HMAC-SHA256 signatures before network admission.
* **Authenticated Peer-to-Peer Telemetry:** All operational swarm traffic is encrypted using **AES-GCM**. This framework generates dynamic 96-bit Initialization Vectors (IVs) to provide true semantic security and actively drops payloads subjected to MITM bit-flipping.
* **Cryptographically Secure Entropy:** To prevent nonce-guessing attacks, the simulation utilizes Java's `SecureRandom` library to generate true 256-bit cryptographic nonces.
* **Empirical Performance Evaluation:** The framework includes a rigorous 1,000-packet empirical execution loop. It dynamically tracks CPU latency via `tic/toc`, measures network overhead, and calculates the true Packet Delivery Ratio (PDR) against simulated Dolev-Yao threat vectors.
* **Fault Tolerance (Bully Algorithm):** Includes standalone election logic to dynamically recover from a single point of failure and promote a new Cluster Head using the Lowest-ID method.

## 📂 Repository File Structure
* **`SwarmAuth_ControlPanel.m`**: Centralized execution hub allowing users to easily launch the main simulation, metrics, or election demos.
* **`main_simulation.m`**: The primary execution script that initializes the swarm, executes mutual authentication handshakes, routes P2P telemetry, and simulates targeted cyber attacks.
* **`swarmauth_performance_metrics.m`**: The Phase 3 empirical evaluation loop. Processes 1,000 packets to calculate legitimate PDR, CPU latency, network overhead, and generates graphical network topologies.
* **`SwarmAuth_ELECTION_DEMO.m` & `SwarmAuth_ELECTION_FIXED.m`**: Standalone simulation scripts demonstrating the Lowest-ID fault-tolerance algorithm for leader recovery.
* **`swarm_init.m`**: Modular initialization function that provisions the 1 Leader and 9 Wingmen with IDs and PSKs.
* **`LeaderDrone.m` & `WingmanDrone.m`**: Object-oriented class definitions representing the drone nodes, containing the logic for challenge issuance, HMAC verification, and key management.
* **`aes_encrypt.m` & `aes_decrypt.m`**: Standalone cryptographic modules utilizing Java Cryptography Extension (JCE) to perform AES-GCM authenticated encryption and MITM tamper detection.
* **`compute_hmac.m`**: Utility function for generating HMAC-SHA256 signatures.
* **`secure_random_bytes.m` & `secure_random_hex.m`**: Entropy modules utilizing `java.security.SecureRandom`.
* **`derive_session_key.m`**: Key Derivation Function (KDF) logic.

## ⚙️ How to Run the Simulation
This project requires **MATLAB (R2026a or newer)** with underlying Java support enabled.

1. **The Easiest Way (Control Panel):**
   Open and run `SwarmAuth_ControlPanel.m` to access the main menu and launch any of the modules below automatically.
2. **Run the Functional Attack Simulation:**
   Run `main_simulation.m`. The terminal will output the results of the 9-node mutual authentication, P2P encryption routing, active attack blocking, and raw hexadecimal data extraction.
3. **Run the Empirical Metrics & Topology Graphs:**
   Run `swarmauth_performance_metrics.m` to execute the 1,000-packet stress test and generate the evaluation charts and topology graphs.
4. **Run the Fault Tolerance Demo:**
   Run `SwarmAuth_ELECTION_FIXED.m` to demonstrate the swarm successfully reorganizing around a new Cluster Head after a critical failure.

## 👥 Development Team
* **Marah Muhannad Zaid Alkilani** | https://github.com/MarahAlkilani
* **Leen Suhail Naqrash** | https://github.com/leennaqarssh-web
* **Rana Mohammad Al-shalout** | https://github.com/r05m
* **Tasnim Samir Abuayyash** | https://github.com/ta099l
