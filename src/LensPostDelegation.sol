// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "@lens/interfaces/ILensHub.sol";
import "@lens/libraries/DataTypes.sol";
import "./interfaces/IVerificator.sol";

contract LensPostDelegation {

    ILensHub lensHub;

    mapping(uint256 => address) verificatorFromProfileId;
    mapping(uint256 => address) profileOwner;
    
    event PostCreated(DataTypes.PostData);

    error AlreadyRegistered();
    error NotYourProfile();
    error ZeroAddressNotAllowed();
    error NotVerifiedToPost();

    constructor (address lensHubAddress) {
        lensHub = ILensHub(lensHubAddress);
    }

    function post
    (
        uint256 profileId,
        string calldata contentURI,
        address collectModule,
        bytes calldata collectModuleInitData,
        address referenceModule,
        bytes calldata referenceModuleInitData
    ) external {
        IVerificator verificator = IVerificator(verificatorFromProfileId[profileId]);
        bool verified = verificator.verify(msg.sender) ;
        if(!verified) revert NotVerifiedToPost();

        DataTypes.PostData memory data = DataTypes.PostData(
            profileId,
            contentURI,
            collectModule,
            collectModuleInitData,
            referenceModule,
            referenceModuleInitData
        );

        lensHub.post(data);

        emit PostCreated(data);
        
    }

    function registerProfile(uint256 profileId, address verificatorAddress) external {
        if(verificatorFromProfileId[profileId] != address(0)) revert AlreadyRegistered();
        verificatorFromProfileId[profileId] = verificatorAddress;
        profileOwner[profileId] = msg.sender;
    }

    function changeVerificator(uint256 profileId, address verificatorAddress) external {
        if(profileOwner[profileId] != msg.sender) revert NotYourProfile();
        verificatorFromProfileId[profileId] = verificatorAddress;
    }

    function changeOwnerOfProfile(uint256 profileId, address newOwner) external {
        if(profileOwner[profileId] != msg.sender) revert NotYourProfile();
        if(newOwner == address(0)) revert ZeroAddressNotAllowed();
        profileOwner[profileId] = newOwner;
    }

    function unregisterProfile(uint256 profileId) external {
        if(profileOwner[profileId] != msg.sender) revert NotYourProfile();
        delete profileOwner[profileId];
        delete verificatorFromProfileId[profileId];
    }
}