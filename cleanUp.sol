uint256 public lastIndex;

    // NOTE: THIS WORKS AND TESTED IS TESTED
    function cleanUp() public {

        if (lastIndex == numberOfCampaigns) {
            revert("no need to clean up, all campaigns have been already checked");
        }

        uint256 currentTimestamp = block.timestamp;
        uint256 deactivationCounter = 0;
        uint256 i = lastIndex;
        int numbersIncreased = 0;
        // Set a threshold of 500 campaigns read 
        int threshold = 500;
        // Set a limit of 50 deactivations per call
        uint256 limit = 50;
        // Iterate through all campaigns in the mapping
        for (i; i < numberOfCampaigns; i++) {
            CampaignDetails storage _campaignDetails = campaignDetails[i];
            CampaignState storage _campaignState = campaignState[i];    
            ++numbersIncreased;
            // Check if three months have passed since the campaign deadline
            if (currentTimestamp >= _campaignDetails.deadline + 7776000) {
                // Check if the campaign has not recieved any donations, if campaign had donations then it should be kept on display for refunds
                if(_campaignState.amountCollected == 0) {
                    // Call the deactivate campaign function
                    DeactivateCampaign(i);
                    deactivationCounter++;
                }
            }
            // if we reach the limit break, 
            if (deactivationCounter == limit || numbersIncreased == threshold) {
                lastIndex = i+1;
                break;
            }
        }   
    }
    
