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
        vk.alpha = Pairing.G1Point(uint256(0x16e9e4763d8263b00a83d7a524f7301a0fe250bc6c494aded21ad97c5983ebc7), uint256(0x1b67b7754407756bdbe63b6004fb846386b0bcbbc69a4e45a6333745e5fd5b14));
        vk.beta = Pairing.G2Point([uint256(0x0d9ae367407b72865a07ad533af730a78307eccfc02d8de6ab4a6e17bf6d2f00), uint256(0x176e9d01552632d8548fbd2dbb5a79ecfd15723ccbb5d99935618641dfb05876)], [uint256(0x13683e967d40eb984ef51dc001e18d018ac503580eb769ee572a4d9dc9819591), uint256(0x25d41da5b34b057d61f0b45513d87245ff6ba3039c0a01cd88501f275a452c95)]);
        vk.gamma = Pairing.G2Point([uint256(0x211254bebddcb6c0b9daae88bb4f34ebda4db8491566ae0007aa00ca52bcf12f), uint256(0x1adf3c1def36866bdcb861b969328e1e231f4af7608d1e6d8dae9071dcd4ae24)], [uint256(0x0cd7b587c9fe378b6cec5278c97ab6470323e3d383bcb04a62ecbb9f0bd2f8f9), uint256(0x0189531adb1176b09bef4ccfb095f51c399d0eb1d401caa2a246125cbbb56085)]);
        vk.delta = Pairing.G2Point([uint256(0x19be7d707856566d2b71303428b0f81f35789e99df8410897dd91377dbf6afe8), uint256(0x1a649d711f0b80fc4400fb47903e9661a50c60f39089a25d1c07aaa429d9f5c9)], [uint256(0x1b10b5ce84f23dfe3d2ba044816f115eb7b973cc1a2e39056a2ce5faa7b88522), uint256(0x10a03da0e4d01d4d83754d14d22a879fa372a932b6fbb5e9e69e71ac64158283)]);
        vk.gamma_abc = new Pairing.G1Point[](7);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1d882a88b6515a7ead1beed45e7194bf091621c47ea13218ac6f777608284752), uint256(0x2c72922c8d2d6e3af562d001fe0f93f402d3498ef7de75b88733367cd73573fe));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1b8f2cd600a816a8fd77f933b44e4b92cc9aeacd844558de1c093ea11ffba37f), uint256(0x0ed3680ae60520ed857edea1217c68aa9af93d2689830e85d90d82fff3905c83));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x09e96b5d0266cb99f9bd7c871ed692d1bc3f638f8dc2c5c542c02a18a930f375), uint256(0x0856a36206703f5926c5489c6cd148d9a39fdcc59d915c8d714d8f332a218e99));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2db935458cc5d37929aa278dbb2d0510ab156681ce28eac019c5b351d372e04c), uint256(0x0ae5ae8f9033505898b603200664b9a3cef4aff3110db0803d827421795e3c28));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0d9e054b2f2bcd93de0db56d0b11fb5e44230761737e127124316a273481c76e), uint256(0x2e2fc22ef00d9aa42fefc1d2a6d336002d521aede9ab1578c923bafadc01db01));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x2d8fca4234944a30017137e4467dc1732c1a3c0fd9c412b4f36bf28bc37e3684), uint256(0x20e17e9e80e32d9fe5df74d5d0bd9ae6805b050189cb66b3f6514fddc9a26d02));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x252813a926b36b8ad21dd0a21b40d844f49ffc479085a5416b9654167503fff1), uint256(0x1f8ebbca3cddbedad4f3fc6bb3d1293534db9218b6ecf7756f5f2aee94eb9cae));
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
