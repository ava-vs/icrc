import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Int "mo:base/Int";

module {
  public type Dip721NonFungibleToken = {
    logo: LogoResult;
    name: Text;
    symbol: Text;
    maxLimit : Nat16;
  };

  public type ApiError = {
    #Unauthorized;
    #InvalidTokenId;
    #ZeroAddress;
    #NoNFT;
    #Other;
  };

  public type Result<S, E> = {
    #Ok : S;
    #Err : E;
  };

  public type OwnerResult = Result<Principal, ApiError>;
  
  public type TxReceipt = Result<Nat, ApiError>;
  
  public type TransactionId = Nat;
  public type TokenId = Nat64;

  public type InterfaceId = {
    #Approval;
    #TransactionHistory;
    #Mint;
    #Burn;
    #TransferNotification;
  };

  public type LogoResult = {
    logo_type: Text;
    data: Text;
  };

  public type Nft = {
    owner: Principal;
    id: TokenId;
    metadata: MetadataDesc;
  };

  public type Subaccount = Blob;
  public type Account = { 
    owner: Principal; 
    subaccount: ?Subaccount 
    };

  public type CollectionMetadata = {
    icrc7_name: Text;
    icrc7_symbol: Text;
    icrc7_royalties: ?Nat16;
    icrc7_royalty_recipient: ?Account;
    icrc7_description: ?Text;
    icrc7_image: ?Blob;
    icrc7_total_supply: Nat;
    icrc7_supply_cap: ?Nat;
  };

  public type Collection = {
    owner: Principal;
    metadata: CollectionMetadata;
    id: Nat;
  };

  public type NftResult = Result<Nft, ApiError>;
  public type CollectionResult = Result<Collection, ApiError>;
  
  public type ExtendedMetadataResult = Result<{
    metadata_desc: MetadataDesc;
    token_id: TokenId;
  }, ApiError>;

  public type MetadataResult = Result<MetadataDesc, ApiError>;

  public type MetadataDesc = [MetadataPart];

  public type MetadataPart = {
    purpose: MetadataPurpose;
    key_val_data: [MetadataKeyVal];
    data: Blob;
  };

  public type MetadataPurpose = {
    #Preview;
    #Rendered;
  };
  
  public type MetadataKeyVal = {
    key: Text;
    val: MetadataVal;
  };

  public type MetadataVal = {
    #TextContent : Text;
    #BlobContent : Blob;
    #NatContent : Nat;
    #Nat8Content: Nat8;
    #Nat16Content: Nat16;
    #Nat32Content: Nat32;
    #Nat64Content: Nat64;
    #IntContent: Int;
    #LinkContent: Text;
  };

  public type MintReceipt = Result<MintReceiptPart, ApiError>;

  public type MintReceiptPart = {
    token_id: TokenId;
    id: Nat;
  };

  public type ReputationBalance = {
    account : Text;
    value : Int;
  };
};
