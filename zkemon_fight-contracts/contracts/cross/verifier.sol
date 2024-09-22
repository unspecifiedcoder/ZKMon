// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x1d2591651ae63a4fe43cf7aa48005135d2c1ccd67160c9f6c7e1ef4b299d06f1), uint256(0x14b37ab3bddf021e0a83170b6f9d1a14c457db3dcc52a05ff2bb7e17205da09c));
        vk.beta = Pairing.G2Point([uint256(0x2387e661893bf5f0408d76c40fdcb9d01702d7a6324f9412b9eb982798b7f0d8), uint256(0x299e21b13c1d515c237884bb14ad73b45634a751a851dda4cdbd1f029e719673)], [uint256(0x302f2fcdbb0eae0a2ef42808b850b187ae525ba0edeb0d3b987eacc784251168), uint256(0x2b16c746641cd4c805c36b409a2313188eb36308f10f20f0d285ceab8f881c2d)]);
        vk.gamma = Pairing.G2Point([uint256(0x129ea71f7d74c1878660755e05b09731bc26d0474937f1eecc0bd266aec43ee1), uint256(0x0de1e768542a040f59e252e83a44389f85efde0e60a627633d5f251aff6c7cc3)], [uint256(0x001b706612a5664c40bbc94f1301175928bb9e0dead2e6d596f8ba83d743deb9), uint256(0x18642dd10c7d201b4740d556fcf99f64b2299bea1b41634cf8f02a3f6f7e1620)]);
        vk.delta = Pairing.G2Point([uint256(0x1cb2ee5076d0df8f155277a4bb2f1bc9117c6b6e47155a18ecc3c63d6571c9bf), uint256(0x0b607f1b48d17f0ba1c98db9b54b085cef8b010649b185d291a01854c80534b0)], [uint256(0x036a8a51d00e65c7b7a4481cfe16a601ebc7fd8fb3a53c73483bc4de3f9958e4), uint256(0x29bb12d7c0653fd947d767009fa5ab2439bb26f8207e07a70e74f08da61fd674)]);
        vk.gamma_abc = new Pairing.G1Point[](7);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x033e655424535dec4b35e500b2c22889cf7b752d30ec73b545ff3e80ee18b688), uint256(0x1fe7e664d5a5e61b5d372c0d42d623d272770fc05e36ab8780baabe6e06c8188));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x2db2e1f7bae8ccafd2b528ab434d7e79635641e73fa157c629088f99c81e240c), uint256(0x1d1184459c565e7cc2a677c9b7166644bda35873108bad3e15ff7dac79e9329f));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x29187434c917f64a733fb23304eabb442c4b9d77b51f142df680d68ddcc3a9be), uint256(0x0d9e41478ea4baa9049cc3b7030d546f3f08b73e368c0ce9a7a4250f787ded0e));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2e0707ef5fcafba05b4a4579ccf32fc8e906fcc87b91c5cb26c553fec20a46cf), uint256(0x16832c93081b4133848ccc3c1ca11dfa43d620bd6d3bd8002db12e3aaff2e9e4));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1c4b6b21c7fbcb12e60034cb825612ceb64e5104ed86b74157338f30991d2689), uint256(0x0d1b9ca015a7ff89fcbb7a82fd4cfcf7cd6220c226a4eb93afd517f79b90ae92));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x28c043cbe26f57de88bd397aeb67c89be2cb77c878fda670e5947b211cd7fd65), uint256(0x0682c04b8df840ca50ad5df7b2f8186b1d2ea183f7a011c9a0c0da1a2e0c409d));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2ef75bcf626f38f8d475715d444a1c7d0aefa1c2a8145dab26f79bc56cf3ea19), uint256(0x1f8256f0cd8e0c3377c5f4d086bcafd496ad4e56bb4a491ab9e6494400b4ac93));
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
