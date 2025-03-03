from vyper.interfaces import ERC20

tokenAQty: public(uint256) #Quantity of tokenA held by the contract
tokenBQty: public(uint256) #Quantity of tokenB held by the contract

invariant: public(uint256) #The Constant-Function invariant (tokenAQty*tokenBQty = invariant throughout the life of the contract)
tokenA: ERC20 #The ERC20 contract for tokenA
tokenB: ERC20 #The ERC20 contract for tokenB
owner: public(address) #The liquidity provider (the address that has the right to withdraw funds and close the contract)

@external
def get_token_address(token: uint256) -> address:
	if token == 0:
		return self.tokenA.address
	if token == 1:
		return self.tokenB.address
	return ZERO_ADDRESS	

# Sets the on chain market maker with its owner, and initial token quantities
@external
def provideLiquidity(tokenA_addr: address, tokenB_addr: address, tokenA_quantity: uint256, tokenB_quantity: uint256):
	assert self.invariant == 0 #This ensures that liquidity can only be provided once
	#Your code here
	self.tokenA = ERC20(tokenA_addr)
	self.tokenA.address = tokenA_addr
	self.tokenA.approve(self.owner,tokenA_quantity)
	self.tokenA.transferFrom(msg.sender, self, tokenA_quantity)
	self.tokenB = ERC20(tokenB_addr)
	self.tokenB.address = tokenB_addr
	self.tokenB.approve(self.owner,tokenA_quantity)
	self.tokenB.transferFrom(msg.sender, self, tokenB_quantity)
	self.owner = msg.sender
	self.tokenAQty = tokenA_quantity
	self.tokenBQty = tokenB_quantity
	self.invariant = tokenA_quantity * tokenB_quantity
	assert self.invariant > 0

# Trades one token for the other
@external
def tradeTokens(sell_token: address, sell_quantity: uint256):
	assert sell_token == self.tokenA.address or sell_token == self.tokenB.address
	#fee: uint256 = sell_quantity / 500
	if sell_token == self.tokenA.address:

		tokenA_in_purchase: uint256 = sell_quantity
		new_tokenAs: uint256 = self.tokenAQty + tokenA_in_purchase
		new_tokenBs: uint256 = self.invariant / new_tokenAs
		self.tokenA.transferFrom(msg.sender,self,tokenA_in_purchase)
		self.tokenB.transfer(msg.sender, self.tokenBQty - new_tokenBs)
		self.tokenAQty = new_tokenAs
		self.tokenBQty = new_tokenBs
	if sell_token == self.tokenB.address:

		tokenB_in_purchase: uint256 = sell_quantity
		new_tokenBs: uint256 = self.tokenBQty + tokenB_in_purchase
		new_tokenAs: uint256 = self.invariant / new_tokenBs
		self.tokenB.transferFrom(msg.sender,self,tokenB_in_purchase)
		self.tokenA.transfer(msg.sender, self.tokenAQty - new_tokenAs)
		self.tokenBQty = new_tokenBs
		self.tokenAQty = new_tokenAs
	

# Owner can withdraw their funds and destroy the market maker
@external
def ownerWithdraw():
	assert self.owner == msg.sender
	self.tokenA.approve(self.owner,self.tokenAQty)
	self.tokenA.transfer(self.owner, self.tokenAQty)
	self.tokenB.approve(self.owner,self.tokenBQty)
	self.tokenB.transfer(self.owner, self.tokenBQty)
	selfdestruct(self.owner)
	