;; NexusVault Protocol - Advanced Bitcoin Yield Aggregation Engine
;;
;; Title: NexusVault - Intelligent Bitcoin Staking Infrastructure
;;
;; Summary: A cutting-edge DeFi protocol that transforms dormant sBTC holdings
;;          into high-yield earning assets through algorithmic staking pools,
;;          automated reward compounding, and risk-optimized vault strategies
;;          that maximize Bitcoin productivity while preserving capital security.
;;
;; Description: NexusVault Protocol establishes a premier staking ecosystem
;;              powered by Stacks' Bitcoin Layer 2 technology. The platform
;;              enables users to deposit synthetic Bitcoin (sBTC) into
;;              algorithmically-managed yield vaults that automatically
;;              optimize returns through intelligent time-lock mechanisms.
;;              Features include adaptive reward distribution, customizable
;;              lock periods, decentralized governance, and real-time yield
;;              optimization that responds to market dynamics for superior
;;              capital efficiency and sustainable returns.

;; ERROR CONSTANTS

(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ZERO_STAKE (err u101))
(define-constant ERR_NO_STAKE_FOUND (err u102))
(define-constant ERR_TOO_EARLY_TO_UNSTAKE (err u103))
(define-constant ERR_INVALID_REWARD_RATE (err u104))
(define-constant ERR_NOT_ENOUGH_REWARDS (err u105))
(define-constant ERR_INVALID_PERIOD (err u106))
(define-constant ERR_OWNER_UNCHANGED (err u107))

;; DATA STORAGE STRUCTURES

;; User staking positions with timestamp tracking
(define-map stakes
  { staker: principal }
  {
    amount: uint,
    staked-at: uint,
  }
)

;; Historical reward claims for transparency and auditing
(define-map rewards-claimed
  { staker: principal }
  { amount: uint }
)

;; PROTOCOL CONFIGURATION VARIABLES

;; Dynamic reward rate in basis points (5 = 0.5% APY)
(define-data-var reward-rate uint u5)

;; Total reward pool available for distribution to stakers
(define-data-var reward-pool uint u0)

;; Minimum staking period in blocks (~10 days on Stacks mainnet)
(define-data-var min-stake-period uint u1440)

;; Total amount of sBTC currently locked in the protocol
(define-data-var total-staked uint u0)

;; Contract owner for administrative functions and governance
(define-data-var contract-owner principal tx-sender)