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

;; ADMINISTRATIVE & GOVERNANCE FUNCTIONS

;; Get the current contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; Transfer ownership to a new principal (governance function)
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq new-owner (var-get contract-owner)))
      ERR_OWNER_UNCHANGED
    )
    (ok (var-set contract-owner new-owner))
  )
)

;; Update the reward rate (owner only) - governance controlled
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (< new-rate u1000) ERR_INVALID_REWARD_RATE) ;; Max 100% (1000 basis points)
    (ok (var-set reward-rate new-rate))
  )
)

;; Update the minimum staking period (owner only) - risk management
(define-public (set-min-stake-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (> new-period u0) ERR_INVALID_PERIOD)
    (ok (var-set min-stake-period new-period))
  )
)

;; Add sBTC to the reward pool for distribution - treasury function
(define-public (add-to-reward-pool (amount uint))
  (begin
    (asserts! (> amount u0) ERR_ZERO_STAKE)
    ;; Transfer sBTC from sender to contract vault
    (try! (contract-call? 'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token
      transfer amount tx-sender (as-contract tx-sender) none
    ))
    ;; Increase reward pool balance
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok true)
  )
)

;; CORE STAKING FUNCTIONS

;; Stake sBTC tokens to earn dynamic rewards
(define-public (stake (amount uint))
  (begin
    (asserts! (> amount u0) ERR_ZERO_STAKE)
    ;; Transfer sBTC from user to protocol vault
    (try! (contract-call? 'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token
      transfer amount tx-sender (as-contract tx-sender) none
    ))
    ;; Update or create stake record with current block height
    (match (map-get? stakes { staker: tx-sender })
      prev-stake
      ;; Add to existing stake (compound position)
      (map-set stakes { staker: tx-sender } {
        amount: (+ amount (get amount prev-stake)),
        staked-at: stacks-block-height,