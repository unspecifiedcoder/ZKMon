// SPDX-License-Identifier: UNLICENSED
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
import "../pairing.sol";

contract CrossVerifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x29080058df7e662b2cfdccca9b17e463e884bcdf412d87e86da4e98b57c0a2a7), uint256(0x0b436ac0f7b5848a8b2325410069e8b40ee65010d0fe13b5fff27f0f11561489));
        vk.beta = Pairing.G2Point([uint256(0x081f3d3ad45d2b0b32d417d2d5a8ab36a1e0a450323ac3fab464e9a1e5065c12), uint256(0x0a22d080ba828a791be74192ee595bf92e5b91a3db0edd1031bc6111e49112f7)], [uint256(0x2d098494938a9b4a7cfab797f54745469a8b40f6a7dad40520f160ccaccf7e93), uint256(0x18f549e9ffcb5d33d9c16ed4290b8e70b9b9993662df75332eee56ecd4264e32)]);
        vk.gamma = Pairing.G2Point([uint256(0x2752c6ad4cab8c8c3fe014d90c1ead1af8641b0366c3e25effeebd0658c6d588), uint256(0x26de3bb583059cbc41fbc77128dcf45ecb570d3a844a01d15b3ca3027f417a28)], [uint256(0x049e4c4c09df355e9535a0d69750bf67d43189e43beb570aa2f25dcfc5ece570), uint256(0x07c5ff34bdac2ffcf7c05fd71ce2d4e95b2a5e4468182e2c3b15ecf1e2e3e119)]);
        vk.delta = Pairing.G2Point([uint256(0x28924cd8665abaf9a8511a3d41f132657e2b3d122f198f543b7db277dbf1d4b2), uint256(0x2a400f4d36679689b440381ffef9fde278455d4142b85287e325b20a0bd8eba0)], [uint256(0x12f9b202089c13eda3020b0ac54c7d130ce859e999390bedc8a4dc2d06275661), uint256(0x08172cbd6d62929d5c6a364fd5b5d8627300fde0258f5e234bf156b7bd9c4aa8)]);
        vk.gamma_abc = new Pairing.G1Point[](7);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x241ac7f522803a75337709f5242f58f7b85f36d4ab749a6dcb9f2fdaf231f099), uint256(0x0f79b1330b1e3d28fb08021fbc7183d8a3ec74fda356da309519096cca0e5bd4));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1220ccef6b892398deb206749d25cabf338ab05d915514be1142483ea8af5378), uint256(0x03ad17f7af35fb71888da555b351ca3bcae78ad12260cc77c2b1db49e6f4096f));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x25a010b9c0dcc4ae5234fe5c41a03db5c7b5993f666cf9ff49c4e113953cfef9), uint256(0x1bc625325aaacb5745a0a4ff10875a8487994ae62bc6e5e6ac41e51cd80f03c6));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x08266d0268d82901035d931540dc50c3f5c03bb3d9129d7ee2878f1c8ea1111d), uint256(0x1ad40fe7a239797577bf28f4f551b152d6f561b06fbd9ef2612b2d81fa1d6a39));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0ebde90b08c5dfed31108fa9e456265792de783d2d77e7b4f1e79df226b6cb73), uint256(0x0c2052513553113ee1c0966e24aa390753bb302e80b438a048717fe099d74d74));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0f2b3028c5e8491350c87185829af6edc73b27d17d1c3a307a2062a984953d8e), uint256(0x245ed65246dff2296987bc261c30524c3121913d6ff855b98ee32778863cb582));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2f42f946b1bd5b324eecc4cc06013ddef6c038f045380cdfc93e0eff008593e5), uint256(0x0fb08a72193185434124b8617f782f70517ebf62b1e0dfd8b17c4244c5efdb18));
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
