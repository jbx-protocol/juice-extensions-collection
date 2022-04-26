pragma solidity ^0.8.0;

//import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";
import '@jbx-protocol-v2/contracts/interfaces/IJBPayDelegate.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

// /!\ This is insecure in this way (no auth check in didPay -> everyone can mint)

contract NFTRewards is ERC721URIStorage, IJBPayDelegate {
  error unAuth();

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721('NFTRewards', 'JBX-NFT') {}

  function didPay(JBDidPayData calldata _param) public override {
    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    _mint(_param.payer, newItemId);
    _setTokenURI(
      newItemId,
      'https://gateway.pinata.cloud/ipfs/QmXMLNsz7LNHA2JViLuUiCoGGVmnhnE3Vc76f2a5EtoGE6'
    );
  }
}
