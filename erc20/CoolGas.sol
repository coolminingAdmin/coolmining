pragma solidity ^0.8.10;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract CoolGas is Initializable,ERC20Upgradeable,AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize (string memory name_, string memory symbol_, address  initialHolder_, uint256  initialSupply_) initializer public {
        __ERC20_init_unchained (name_, symbol_);
        __AccessControl_init_unchained();
        _mint(initialHolder_, initialSupply_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    }
    function mint(address account, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(account, amount);
    }
    function burn(address account, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(account, amount);
    }
    function mintGas(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }
}