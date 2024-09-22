// SPDX-License-Identifier: UNLICENSED
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;

import "../pairing.sol";

contract FightVerifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x1f46f062f4c24e69c404f87fca4800e97d0fb70b7f8fc1a01680a47ced27b070), uint256(0x16315b77fa19bd78319fbfb0b4be29c211d26aff44fee5e493c040993df7e851));
        vk.beta = Pairing.G2Point([uint256(0x1a5b688fe35196908586e8151b1744e8c0e857853856fd066a551894a0c83ee7), uint256(0x201fd4145d88b68d06d4bde65f0d476429a17765a998a1f02fed9fed9c594d4e)], [uint256(0x0c01345fb1602eb75ec9070e713d7f21963f5569894ebbf4f7513a27c58f3234), uint256(0x1b0e52769d685de686537d0a94d633577ed4220130f49a2bf3a978b742fad570)]);
        vk.gamma = Pairing.G2Point([uint256(0x2b2aaaac4a014e39735bbaed3d69a455e6957edfb3b06342bd6bdcdc8139791e), uint256(0x068dc4afe6577007f43c78ac0b47e06b4273f500b5e8ba5c7149e935b4557692)], [uint256(0x001fcc47520fa9f490a5d6e5fec2d756a26dcdf2490939fe52556da503a617b0), uint256(0x2c03cf77d86b0b339091566649e8bd6cd63cfbcfda0b4cd4ad53c4d3c7de278d)]);
        vk.delta = Pairing.G2Point([uint256(0x0dae943a80fbb92b59ec0e40cba6b435b8ef7e11523001af4fce29f3930645d6), uint256(0x2e50712024281a17f8b5c5d878de78eb1d611fc8f1a4336ec1d9d7108a76e8ae)], [uint256(0x0b90d14923fe57afed5b33d2d913a01e6e0bb2ebd57b4dab10428a00a1991b0e), uint256(0x2653a651004e92c8ef82abb3a6538839c5e31bf9af51dc5f0364948918135baa)]);
        vk.gamma_abc = new Pairing.G1Point[](6);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x03680df45997a81c8ff4a9dae89c454c7f28a6f473af5d1f73ba9c7b1bf6c767), uint256(0x19b6e1790e73c8671d8eac5d54346e98676e7262cf592a7d50e8e7d6217670e0));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x27b6e98da7c23fd1746bad2eed68fc105d81fe45ddb5a44ea4c86949242eab8d), uint256(0x2f3664942a87bdb941baf62e3390bc6b20cbb3dd545e10993e202c935068acfe));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x29e119f39f65c7f3cdfacd7b30769cc42c69a0c19f2ebd5450b7d2e4db226e88), uint256(0x2f95a943d12e81058c436cd2306cd186b0245db02a0df0d738ea393841071731));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x12e1952ad82cb1fd6120bebc39e7f2a4ca4c25dd53af662767c7a4198c385bd4), uint256(0x0b838ab873c74d0e8b57a83dd3759753763524258e0dd6b771b47ba84a8fac1e));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1ae7fb3b6f82f7f2e10892ebc39a2e0e2a089e1bf2e158abd8a1442ad028b582), uint256(0x29c4cc1fb262cc7ec4ba4c7792de6bcb4790b92b17a40c106bbc06932ab42a17));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x01e8cfa5a03da0c464cef6c14b82407e64403a8b8a4e4b7b714d028dc2fcd401), uint256(0x22b79a0787709509aa62bb77ae7d376e7dfc64ea5c853248b44937d11133bfc2));
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
            Proof memory proof, uint[5] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](5);
        
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
