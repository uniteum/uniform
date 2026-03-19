// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "erc20/ERC20.sol";
import {IERC20Metadata} from "ierc20/IERC20Metadata.sol";
import {SafeERC20} from "erc20/SafeERC20.sol";
import {IAddressLookup} from "ilookup/IAddressLookup.sol";
import {IUniform} from "ilookup/IUniform.sol";
import {Clones} from "clones/Clones.sol";

/// @title UniformToken
/// @notice A wrapped ERC-20 that presents the same address across every chain.
/// @dev The underlying token is resolved from an immutable locale lookup.
///      The contract is its own factory: call {make} to deploy a new clone via CREATE2.
contract UniformToken is ERC20, IUniform {
    using SafeERC20 for IERC20Metadata;

    /// @notice The prototype instance used as the EIP-1167 implementation.
    address public immutable PROTOTYPE = address(this);

    /// @notice Returns the underlying token for this chain.
    IERC20Metadata public underlying;

    /// @notice Emitted when underlying tokens are deposited and uniform tokens are minted.
    event Deposit(address indexed account, uint256 amount);

    /// @notice Emitted when uniform tokens are burned and underlying tokens are withdrawn.
    event Withdraw(address indexed account, uint256 amount);

    constructor() ERC20("Uniform Factory", "PROTOTYPE") {}

    /// @inheritdoc IUniform
    function made(
        IAddressLookup locale_
    ) public view returns (bool exists, address home, bytes32 salt) {
        salt = keccak256(abi.encode(locale_));
        home = Clones.predictDeterministicAddress(PROTOTYPE, salt, PROTOTYPE);
        exists = home.code.length > 0;
    }

    /// @inheritdoc IUniform
    function make(IAddressLookup locale_) external returns (address token) {
        (bool exists, address home, bytes32 salt) = made(locale_);
        token = home;
        if (!exists) {
            Clones.cloneDeterministic(PROTOTYPE, salt, 0);
            UniformToken(home).zzInit(locale_);
        }
    }

    /// @notice Initialiser called by the prototype on a freshly exists clone.
    /// @dev Reverts with {Unauthorized} if called by any address other than the prototype.
    function zzInit(IAddressLookup locale_) public {
        if (msg.sender != PROTOTYPE) revert Unauthorized();
        emit Made(address(this), locale_);
        underlying = IERC20Metadata(locale_.value());
    }

    /// @notice Returns the name of the token, matching the underlying token.
    function name() public view override returns (string memory) {
        return underlying.name();
    }

    /// @notice Returns the symbol of the token, matching the underlying token.
    function symbol() public view override returns (string memory) {
        return underlying.symbol();
    }

    /// @notice Returns the number of decimals, matching the underlying token.
    function decimals() public view override returns (uint8) {
        return underlying.decimals();
    }

    /// @notice Deposit underlying tokens and mint an equal amount of uniform tokens.
    /// @param amount The amount to deposit.
    function deposit(uint256 amount) external {
        address sender = _msgSender();
        underlying.safeTransferFrom(sender, address(this), amount);
        _mint(sender, amount);
        emit Deposit(sender, amount);
    }

    /// @notice Burn uniform tokens and withdraw an equal amount of underlying tokens.
    /// @param amount The amount to withdraw.
    function withdraw(uint256 amount) external {
        address sender = _msgSender();
        _burn(sender, amount);
        underlying.safeTransfer(sender, amount);
        emit Withdraw(sender, amount);
    }
}
