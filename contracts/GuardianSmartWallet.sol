// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Simple Smart Contract Wallet
 * @notice Features:
 *  - One owner
 *  - Can receive ETH
 *  - Owner can send ETH or call any contract
 *  - Allowances: certain addresses can spend limited amounts
 *  - Guardians (5 total): 3-of-5 can change the owner if needed
 */
contract SimpleWallet {
    // Wallet owner
    address payable public owner;

    // Allowances
    mapping(address => uint256) public allowance;
    mapping(address => bool) public isAllowedToSend;

    // Guardians (exactly 5 max)
    mapping(address => bool) public guardians;
    uint256 public guardiansTotal; // how many guardians are set

    // Required votes (3 out of 5)
    uint256 public constant GUARDIANS_REQUIRED = 5;
    uint256 public constant GUARDIANS_THRESHOLD = 3;

    // Votes for a proposed new owner
    mapping(address => uint256) public votesFor;
    mapping(address => mapping(address => bool)) public hasVoted; 

    constructor() {
        owner = payable(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                              RECEIVE / FALLBACK                             */
    /* -------------------------------------------------------------------------- */

    // Accept ETH
    receive() external payable {}
    fallback() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                              OWNER SETTINGS                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Set or remove a guardian (only owner)
     * @param _guardian Address to add/remove
     * @param _isGuardian True = make guardian, False = remove
     */
    function setGuardian(address _guardian, bool _isGuardian) external {
        require(msg.sender == owner, "Only owner");
        require(_guardian != address(0), "Zero address");

        if (_isGuardian) {
            require(!guardians[_guardian], "Already guardian");
            require(guardiansTotal < GUARDIANS_REQUIRED, "Max 5 guardians");
            guardians[_guardian] = true;
            guardiansTotal++;
        } else {
            require(guardians[_guardian], "Not a guardian");
            guardians[_guardian] = false;
            guardiansTotal--;
        }
    }

    /**
     * @notice Set allowance for an address
     */
    function setAllowance(address _who, uint256 _amount) external {
        require(msg.sender == owner, "Only owner");

        allowance[_who] = _amount;
        isAllowedToSend[_who] = _amount > 0;
    }

    /* -------------------------------------------------------------------------- */
    /*                           EXECUTE TRANSACTIONS                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Send ETH or execute a call to any address (EOA or contract)
     * @param _to Recipient address
     * @param _value Amount of ETH to send
     * @param _data Call data (leave empty for simple ETH transfer)
     */
    function execute(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes memory) {
        require(_to != address(0), "Zero address");
        require(address(this).balance >= _value, "Not enough funds");

        // If caller is NOT the owner, check allowance
        if (msg.sender != owner) {
            require(isAllowedToSend[msg.sender], "Not allowed");
            require(allowance[msg.sender] >= _value, "Allowance too low");
            allowance[msg.sender] -= _value;

            // Disable sending if allowance hits zero
            if (allowance[msg.sender] == 0) {
                isAllowedToSend[msg.sender] = false;
            }
        }

        // low-level call supports sending ETH + calling functions on other contracts
        (bool success, bytes memory returnData) = _to.call{value: _value}(_data);
        require(success, "Call failed");

        return returnData;
    }

    /* -------------------------------------------------------------------------- */
    /*                           GUARDIAN RECOVERY LOGIC                           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Guardians vote to set a new owner. Needs 3 of 5.
     * @param _proposedOwner Address to become the new owner
     */
    function proposeNewOwner(address payable _proposedOwner) external {
        require(guardians[msg.sender], "Not guardian");
        require(_proposedOwner != address(0), "Zero address");
        require(guardiansTotal == GUARDIANS_REQUIRED, "Must have exactly 5 guardians");

        // Guardian must not vote twice for the same proposal
        require(!hasVoted[_proposedOwner][msg.sender], "Already voted");

        hasVoted[_proposedOwner][msg.sender] = true;
        votesFor[_proposedOwner]++;

        // If threshold reached → change owner
        if (votesFor[_proposedOwner] >= GUARDIANS_THRESHOLD) {
            owner = _proposedOwner;
            votesFor[_proposedOwner] = 0; // reset votes
        }
    }

    /**
     * @notice Guardians can revoke their vote BEFORE threshold is reached
     */
    function revokeVote(address _proposedOwner) external {
        require(guardians[msg.sender], "Not guardian");
        require(hasVoted[_proposedOwner][msg.sender], "No vote to revoke");

        hasVoted[_proposedOwner][msg.sender] = false;

        if (votesFor[_proposedOwner] > 0) {
            votesFor[_proposedOwner]--;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                 VIEW HELPERS                                */
    /* -------------------------------------------------------------------------- */

    function isGuardian(address _addr) external view returns (bool) {
        return guardians[_addr];
    }

    function getVotes(address _proposedOwner) external view returns (uint256) {
        return votesFor[_proposedOwner];
    }
}
