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
* **Empirical Performance Evaluation:** The framework includes a rigorous 1,000-packet empirical execution loop (`swarmauth_performance_metrics.m`). It dynamically tracks CPU latency via `tic/toc`, measures network overhead, and calculates the true Packet Delivery Ratio (PDR) against simulated Dolev-Yao threat vectors.

## 📂 Repository File Structure
* `main_simulation.m`: The primary execution script that initializes the swarm, executes the mutual authentication handshakes, routes P2P telemetry, and simulates targeted cyber attacks.
* `swarmauth_performance_metrics.m`: The Phase 3 empirical evaluation loop. Processes 1,000 packets to calculate legitimate PDR, CPU latency, and network overhead, and generates the graphical network topologies.
* `swarm_init.m`: Modular initialization function that provisions the 1 Leader and 9 Wingmen with IDs and PSKs.
* `LeaderDrone.m` & `WingmanDrone.m`: Object-oriented class definitions representing the drone nodes, containing the logic for challenge issuance, HMAC verification, and key management.
* `aes_encrypt.m` & `aes_decrypt.m`: Standalone cryptographic modules utilizing Java Cryptography Extension (JCE) to perform AES-GCM authenticated encryption and MITM tamper detection.
* `compute_hmac.m`: Utility function for generating HMAC-SHA256 signatures.
* `secure_random_bytes.m` & `secure_random_hex.m`: Entropy modules utilizing `java.security.SecureRandom`.
* `derive_session_key.m`: Key Derivation Function (KDF) logic.

## ⚙️ How to Run the Simulation
This project requires **MATLAB (R2026a or newer)** with underlying Java support enabled.

1. **Run the Functional Attack Simulation:**
   Open and execute `main_simulation.m`. The terminal will output the results of the 9-node mutual authentication, P2P encryption routing, and the active blocking of Injection, Impersonation, and Replay attacks.
2. **Run the Empirical Metrics & Topology Graphs:**
   Open and execute `swarmauth_performance_metrics.m`. This will run the 1,000-packet stress test and generate three pop-up figures:
   * **Figure 1:** Empirical Evaluation Metrics (PDR, Latency, Overhead).
   * **Figure 2:** Modality A (Centralized UAV-to-CH Authentication Star Graph).
   * **Figure 3:** Modality B (Decentralized UAV-to-UAV P2P Telemetry Mesh Graph).

## 👥 Development Team
* **Marah Muhannad Zaid Alkilani** | https://github.com/MarahAlkilani
* **Leen Naqrash** | https://github.com/leennaqarssh-web
* **Rana Al-shalout** | https://github.com/r05m
* **Tasnim Abuayyash** | https://github.com/ta099l
