// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract QuickFundAlpha {
    // default address to which fees are sent
    address payable defaultFeesAddress = payable(0xc69848d26622b782363C4C9066c9787a270E9232);

    // address of the contract owner
    address public owner;

    // constructor to set the contract owner to the address that deploys the contract
    constructor() public {
        owner = msg.sender;
     }

    // modifier to allow only the owner to execute a function
    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can call this function.");
     _;
    }
    
    // struct to store information about a campaign
    struct Campaign {
        address owner; // address of the campaign owner
        string title; // title of the campaign
        string description; // description of the campaign
        uint256 target; // target amount to be raised
        uint256 deadline; // deadline for the campaign
        uint256 amountCollected; // amount of native coins collected
        string[] image; // image for the campaign
        string category; // category of the campaign
        string[] video; // video for the campaign
        address[] donators; // array to store addresses of donators
        string [] donatorsNotes; // array to store notes from donators
        uint256[] donations; // array to store donations
        string[] donationsCoins; // array to store other coin donations
        string[] updates; // array to store other campaign updates
        string[] milestones; // array for campaign milestones
    }

    // mapping to store campaign information
    mapping(uint256 => Campaign) public campaigns;

    // variable to keep track of the number of campaigns
    uint256 public numberOfCampaigns = 0;

    // function to create a new campaign
    function createCampaign(address _owner,
     string memory _title, 
     string memory _description, 
     uint256 _target, 
     uint256 _deadline, 
     string memory _category, 
     string [] memory _image, 
     string [] memory _video,
     string [] memory _milestones
     ) public returns (uint256) {

        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.category = _category;
        campaign.image = _image;
        campaign.video = _video;
        campaign.milestones = _milestones;
        campaign.updates.push("");

        numberOfCampaigns++;

        return numberOfCampaigns - 1;

    }

    function updateCampaign(
        uint256 pid,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _category,
        string[] memory _image,
        string[] memory _video,
        string[] memory _milestones
    ) public {

        Campaign storage campaign = campaigns[pid];

        // Ensure that only the campaign owner can update the campaign
        require(msg.sender == campaign.owner, "Only the campaign owner can update the campaign.");
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        // Update campaign fields
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.category = _category;
        campaign.image = _image;
        campaign.video = _video;
        campaign.milestones = _milestones;
    }


    function pushUpdateCampaign(
        uint256 pid,
        string memory _update
    ) public {
        Campaign storage campaign = campaigns[pid];
        // Ensure that only the campaign owner can update the campaign
        require(msg.sender == campaign.owner, "Only the campaign owner can push updates to the campaign.");
        //Push Updates to Campaign
        campaign.updates.push(_update);
    }

   
    function donateToCampaign(uint256 _id, string memory note, string memory symbol) public payable {
        
        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline > block.timestamp, "The deadline for this campaign has passed.");

        uint256 amount = msg.value;
        require((msg.sender.balance) > amount, "Insufficient balance");

        uint256 fees = amount / 100;

        // check fees were sent to campaign
        (bool feesSent,) = payable(defaultFeesAddress).call{value: fees}("");
        require(feesSent, "Error transferring fees.");

        (bool sentOther,) = payable(campaign.owner).call{value: amount - fees}("");
        require(sentOther, "Error transferring funds to campaign owner.");
        
        campaign.amountCollected = campaign.amountCollected + (amount - fees);
        campaign.donators.push(msg.sender);
        campaign.donatorsNotes.push(note);
        campaign.donations.push(amount - fees);
        campaign.donationsCoins.push(symbol);

    }

    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory, string[] memory, string [] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations, campaigns[_id].donatorsNotes, campaigns[_id].donationsCoins);

    }

    function transferOther(uint256 _id, uint256 _amount, string memory symbol, string memory note, address payable coin_addy) public { 
        
        // create function that you want to use to fund your contract or transfer that token
        IERC20 token = IERC20(coin_addy);

        uint256 fees = _amount / 100;

        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline > block.timestamp, "The deadline for this campaign has passed.");

        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance of token");

        (bool feesSent) = token.transferFrom(msg.sender, defaultFeesAddress, fees);
        require(feesSent, "Error transferring fees.");

        (bool sentOther) = token.transferFrom(msg.sender, campaign.owner, (_amount - fees));
        require(sentOther, "Error transferring payment.");

        campaign.donators.push(msg.sender);
        campaign.donatorsNotes.push(note);
        campaign.donations.push(_amount - fees);
        campaign.donationsCoins.push(symbol);
    }


    function getCampaigns() public view returns(Campaign[] memory){
        // Getting campagigns from memory
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        
        // loop and populate, then return all campaigns.
        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function setDefaultFeesAddress(address payable _newAddress) public onlyOwner {
        require(_newAddress != address(0), "The new address cannot be the zero address.");
        defaultFeesAddress = _newAddress;
    }

    function getDefaultFeesAddress() public view returns (address) {
        return defaultFeesAddress;
    }

    function removeCampaign(uint256 campaignId) public onlyOwner {
        // Get the campaign struct from the mapping
        Campaign storage campaign = campaigns[campaignId];
        
        // Ensure that only the contract owner can remove the campaign
        require(msg.sender == owner, "Only the contract owner can remove the campaign.");

        // check if three months have passed since the campaign deadline
        require(block.timestamp >= campaign.deadline + 7776000, "three months have not passed since the campaign deadline");

        // check if the campaign has reached its goal
        require(campaign.amountCollected < campaign.target, "the campaign has reached its goal");

        // delete all campaign data
        delete campaign;

        // decrement the number of campaigns
        numberOfCampaigns--;
    }


    function openVote(uint256 pid) public {
        Campaign storage campaign = campaigns[pid];
        require(msg.sender == campaign.owner, "Only the campaign owner can open a vote.");
        require(block.timestamp > campaign.deadline && block.timestamp <= campaign.deadline + 604800 && campaign.amountCollected < campaign.target && campaign.type == CampaignType.Secured && campaign.voteOpen == false, "Vote can only be open if deadline passed and goal not met and campaign is Secured and vote is not open already, and deadline is not passed by more than 7 days.");
        campaign.voteOpen = true;
        campaign.voteDeadline = block.timestamp + 604800;
    }


    
    function cleanUp() public onlyOwner {
        // Get the current block timestamp
        uint256 currentTimestamp = block.timestamp;
        
        // Iterate through all campaigns in the mapping
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            // Get the campaign struct from the mapping
            Campaign storage campaign = campaigns[i];
            
            // Check if three months have passed since the campaign deadline
            if (currentTimestamp >= campaign.deadline + 7776000) {
                // Emit the CampaignDeadlineReached event
                //emit CampaignDeadlineReached(i);
                
                // Check if the campaign has reached its target
                if(campaign.amountCollected < campaign.target) {
                    // Call the remove campaign function
                    removeCampaign(i);
                }
            }
        }
    }

}
