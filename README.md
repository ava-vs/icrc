# ICRC-7 NFT Canister

This canister implements the ICRC-7 token ([draft](https://github.com/dfinity/ICRC/blob/main/ICRCs/ICRC-7/ICRC-7.md)) standard on the Internet Computer blockchain for [aVa Verification](https://github.com/ava-vs/verification) project. 

## Features

- Mint non-fungible tokens (dynamic NFTs)
- Create dNFT collections
- Add dNFTs from collections
- Update dNFT metadata
- Retrieve dNFT metadata history

## Usage

The main methods provided are:

- `mint` - Mint a new NFT
- `updateMetadata` - Update metadata for an owned NFT  
- `createCollection` - Create a new NFT collection
- `addTokenToCollection` - Add an NFT to a collection  
- `getCollectionTokens` - Get all NFTs in a collection

The canister also exposes queries to:

- `currentNft` - Get an owned NFT
- `getAllTokenIds` - Get all minted NFT IDs  
- `getCollections` - Get all collections
- `getAllMetadata` - Get metadata for all NFTs 
- `getHistoryByTokenId` - Get historical metadata for an NFT

## Technical Details

The canister is implemented in Motoko and manages state using stable variables. Some key elements:

- `tokenEntries` - Map of owner principal to NFT ID
- `metadataMap` - NFT ID to metadata  
- `historyMap` - NFT ID to array of historical metadata logs
- `collectionEntries` - Map of collection ID to array of NFT IDs

The canister interfaces with the Internet Computer blockchain for persistence.

## Next Steps

Potential future improvements:

- Support transferring NFT ownership
- Royalty payments on NFT sales 
- Additional metadata standards (e.g. attributes)
- Access control for methods

## Running the project locally

If you want to test your project locally, you can use the following commands:

```bash
# Starts the replica, running in the background
dfx start --background

# Deploys your canisters to the replica and generates your candid interface
dfx deploy
```
