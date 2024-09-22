// SPDX-License-Identifier: UNLICENSED
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
import "../pairing.sol";

contract BreedVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x2e40d9749d89ade35c525772f1d5b40c079e72563d8c9cff6f8c5ea9fefbdb15), uint256(0x17adcdf79ddc65e97059e97cc1635e9711757333e065abeaf608ebb7edb807ae));
        vk.beta = Pairing.G2Point([uint256(0x2e6400f9cd604c180d3de209edd943b5d5c0e5fef1c6eff25034ef52450ead8e), uint256(0x2a9c579e333897233a85313318e3018fc4d08b6e6adb7517223a16cff64beb34)], [uint256(0x0a5c38797ff4a116495a7e4549f05f9e7ebf0a5a401d2a2c02287f2ded2763ab), uint256(0x0f95876cbf57a0264fe7e9d40d59a311347ce2c36821639c5aa6dc59cafb153d)]);
        vk.gamma = Pairing.G2Point([uint256(0x0cc0d3c620953d244e3e9a9a2280841934d648e0671d4d3ea500baa0dfed5b84), uint256(0x1ec8f4e1904d32692380ef48ae341441e1d923bdfefe18e2959fd2f953fe1928)], [uint256(0x1d39c460aca4a18d261ca9bc485a1a73d766b38a1b3b96fe63eac8b6fae088c2), uint256(0x275357854372a2c6eb74823c95760e78e1ae03c2039ffb5e560e855481213acf)]);
        vk.delta = Pairing.G2Point([uint256(0x070fb9367079fbf71b7519c4320e64b19b22dfca5ac58584a545dec022a84f3f), uint256(0x054a20c020b39c66d9dbdcb23d4c1a99e87df2315ee16d86fea1b040896df420)], [uint256(0x01721fa8d229d5cbc31505e1c46786cf04efd3fd415e3f76039e344ebdb62915), uint256(0x14761cbedfceac98d71eba1892fc2153e26ecc7242b25eb2fdb8e887bd1c59a2)]);
        vk.gamma_abc = new Pairing.G1Point[](7);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x287287e93f76db1b4b146825b9073d99891964976269c8b76dd76bc89396e84e), uint256(0x26b42d9de5014ec55c084fb41a18bd7284a9dd80630e59f3a6bfba41179f101d));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x20779809f1dd7c2dd89de28bf8ebaa180dbf077d6554610e8b104d92ec0eb819), uint256(0x218983a6a0414bb2772446d28fd62e38f22b985737aeff7835ee4a237250e7f2));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2d801da06b512bd918e9ca6567a5ba495dd1ccbfb95b18be7aa0c1edb05188c4), uint256(0x0a00c9ed1c833fb93aadb2c2ecda351513c9dcddf6de31ee57e54ff98b8a611a));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0951e286fc320fda532e7eda228347940a436655d104304925af4caca38d74cd), uint256(0x2daaf16fd7c2048661187b0d3d9605a02bc797a4670a7d81957e7e468ade5a75));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x299c30e777eecc8358c7c4332e8ce1e16f560acf6ba0ce37360117b057762a99), uint256(0x00f1471efa2e1f9026dbb4115acedacce223c02b72fd2bdc7a169891315a35a6));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x228e570210545e4dc88c51fc14a3a3d1815cc17603881790d862c705e765c30b), uint256(0x18052917ecc2097604e54c423c151e167eae1ddadd8f057cb06fe8c06ed24239));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1cb15d2ae4aa87b378717608b0a65d58e678220e308a74e09d0fb7da8bc7ee1c), uint256(0x0cc36c9f8bb1a54c8e8ebbc517fdaf390a0ff91f18a13d78137b5ee3731a4226));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[6] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](6);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
