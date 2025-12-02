


# 📘 Smart Contract Wallet — Solidity Implementation

## 📌 Overview

This project implements a **Smart Contract Wallet** written in Solidity that provides:

* ✔️ One single owner
* ✔️ Ability to **receive ETH at any time**
* ✔️ Owner can **send ETH or call any contract**
* ✔️ Allowances for specific addresses
* ✔️ **Guardian recovery system** (3 out of 5 guardians can change the owner)

This wallet is designed to be simple, secure, and easy to understand for developers who are learning Solidity.

---

## 🎯 Features

### 1️⃣ **Single Owner**

The wallet has exactly **one owner**, who:

* Can manage guardians
* Can set allowances
* Can execute transactions

The owner is assigned automatically during deployment.

---

### 2️⃣ **Receive ETH**

The wallet includes:

* `receive()`
* `fallback()`

These allow the contract to accept ETH **from any source**, including:

* Direct transfers
* Contract calls
* `send()`
* `transfer()`
* `call{value: ...}`

---

### 3️⃣ **Spend Funds (Owner & Allowances)**

#### 👤 Owner

The owner can:

* Send ETH to any address
* Call any smart contract
* Include calldata to trigger functions on contracts

#### 👥 Allowed Users

Specific addresses can be given:

* A **maximum spend limit** (`allowance`)
* Permission to make transactions on behalf of the wallet

Example use cases:

* Giving a friend limited spending
* Allowing an external bot to run calls on behalf of the wallet

---

### 4️⃣ **Allowances**

The owner can set how much ETH an address can spend.

When they spend ETH:

* Allowance decreases
* If it reaches 0 → permission is removed automatically

---

### 5️⃣ **Guardian System (3 of 5 Recovery)**

The wallet supports a recovery mechanism using **guardians**.

* The owner may assign up to **five guardians**
* Guardians can vote to assign a new owner
* When **3 guardians** vote for the same address → owner changes automatically

This protects the owner in case they:

* Lose access to their private key
* Get hacked
* Need to rotate ownership

Additionally:

* Guardians can **revoke their vote** before reaching 3/5

---

## 🗂️ Contract Architecture

### Main Components

| Component         | Description                                |
| ----------------- | ------------------------------------------ |
| `owner`           | Current wallet owner                       |
| `guardians`       | List of up to 5 trusted addresses          |
| `allowance`       | Limit of ETH that an address can spend     |
| `isAllowedToSend` | Whether an address has permission to spend |
| `votesFor`        | Guardian votes for proposed new owner      |
| `hasVoted`        | Mapping to prevent double voting           |

---

## 🔐 Security Considerations

* Only the **owner** can set guardians or allowances
* Guardians must not vote twice for the same proposal
* Guardians must be exactly **5** for the recovery process
* ETH transfers use `.call{value: ...}` for flexibility
* Zero address inputs are rejected

---

## 🛠️ Main Functions

### 👑 Owner / Permissions

| Function                     | Description                     |
| ---------------------------- | ------------------------------- |
| `setGuardian(address,bool)`  | Add / remove guardians          |
| `setAllowance(address,uint)` | Allow an address to spend funds |

---

### 💸 Executing Transactions

| Function                      | Description               |
| ----------------------------- | ------------------------- |
| `execute(address,uint,bytes)` | Send ETH / call contracts |

---

### 🛡️ Guardian Recovery

| Function                   | Description                  |
| -------------------------- | ---------------------------- |
| `proposeNewOwner(address)` | Guardian votes for new owner |
| `revokeVote(address)`      | Remove vote before threshold |

---

## ▶️ How to Use

### 1. Deploy Contract

* Deploy using Remix, Hardhat, Foundry, or any EVM-compatible chain.
* The deployer becomes the **owner**.

### 2. Set Guardians

Owner assigns 5 trusted addresses:

```solidity
setGuardian(address, true);
```

### 3. Set Allowance

Owner gives spending rights:

```solidity
setAllowance(user, 1 ether);
```

### 4. Execute Transactions

Owner or allowed user:

```solidity
execute(to, amount, data);
```

### 5. Recover Owner (3 of 5 Guardians)

Guardians call:

```solidity
proposeNewOwner(newOwner);
```

When 3 guardians vote → the owner changes.

---

## 🧩 Requirements Implemented

* ✔️ **One owner**
* ✔️ **Wallet receives funds always**
* ✔️ **Owner can spend funds or call any address**
* ✔️ **Allow allowances for other users**
* ✔️ **Guardians can change owner with 3/5 votes**

---

## 📄 License

MIT License.