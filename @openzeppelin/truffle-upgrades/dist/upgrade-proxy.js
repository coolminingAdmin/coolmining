"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.upgradeProxy = void 0;
const upgrades_core_1 = require("@openzeppelin/upgrades-core");
const utils_1 = require("./utils");
async function upgradeProxy(proxy, Contract, opts = {}) {
    const { deployer } = (0, utils_1.withDefaults)(opts);
    const provider = (0, utils_1.wrapProvider)(deployer.provider);
    const proxyAddress = (0, utils_1.getContractAddress)(proxy);
    const upgradeTo = await getUpgrader(provider, Contract, proxyAddress);
    const { impl: nextImpl } = await (0, utils_1.deployImpl)(Contract, opts, proxyAddress);
    const call = encodeCall(Contract, opts.call);
    await upgradeTo(nextImpl, call);
    Contract.address = proxyAddress;
    return new Contract(proxyAddress);
}
exports.upgradeProxy = upgradeProxy;
async function getUpgrader(provider, contractTemplate, proxyAddress) {
    const adminAddress = await (0, upgrades_core_1.getAdminAddress)(provider, proxyAddress);
    const adminBytecode = await (0, upgrades_core_1.getCode)(provider, adminAddress);
    if (adminBytecode === '0x') {
        // No admin contract: use TransparentUpgradeableProxyFactory to get proxiable interface
        const TransparentUpgradeableProxyFactory = (0, utils_1.getTransparentUpgradeableProxyFactory)(contractTemplate);
        const proxy = new TransparentUpgradeableProxyFactory(proxyAddress);
        return (nextImpl, call) => (call ? proxy.upgradeToAndCall(nextImpl, call) : proxy.upgradeTo(nextImpl));
    }
    else {
        // Admin contract: redirect upgrade call through it
        const manifest = await upgrades_core_1.Manifest.forNetwork(provider);
        const AdminFactory = (0, utils_1.getProxyAdminFactory)(contractTemplate);
        const admin = new AdminFactory(adminAddress);
        const manifestAdmin = await manifest.getAdmin();
        if (admin.address !== (manifestAdmin === null || manifestAdmin === void 0 ? void 0 : manifestAdmin.address)) {
            throw new Error('Proxy admin is not the one registered in the network manifest');
        }
        return (nextImpl, call) => call ? admin.upgradeAndCall(proxyAddress, nextImpl, call) : admin.upgrade(proxyAddress, nextImpl);
    }
}
function encodeCall(factory, call) {
    var _a;
    if (!call) {
        return undefined;
    }
    if (typeof call === 'string') {
        call = { fn: call };
    }
    const contract = new factory.web3.eth.Contract(factory._json.abi);
    return contract.methods[call.fn](...((_a = call.args) !== null && _a !== void 0 ? _a : [])).encodeABI();
}
//# sourceMappingURL=upgrade-proxy.js.map