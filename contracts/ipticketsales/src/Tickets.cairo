#[starknet::contract]

 use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess, MutableVecTrait,
        Vec, VecTrait,
    };
 use starknet::{
        ContractAddress, get_block_timestamp, get_caller_address, contract_address_const,
        get_contract_address
    };
    struct TicketMetadata {
        price: u256,
        quantity: u256,
        expiration: felt252,
        royalties: felt252,
        royalty_recipient: felt252
    }
    #[storage]
    struct Storage {
    tickets: Map<u256, TicketMetadata>,  // ticket_id -> TicketMetadata
    owners: Map<u256, felt252>,          // ticket_id -> owner address
    balances: Map<felt252, u256>,        // user address -> deposited funds
    }


    #[event]
    func TicketMinted(ticket_id: u256, owner: felt252, date: felt252):
    end

    #[event]
    func TicketPurchased(ticket_id: u256, buyer: felt252, date: felt252):
    end

    #[event]
    func AccessGranted(ticket_id: u256, user: felt252, date: felt252):
    end

    #[event]
    func TicketResold(ticket_id: u256, seller: felt252, buyer: felt252, date: felt252):
    end


    #[abi(embed_v0)]
    impl TicketMarketplace of TicketMarketplace<Storage> {
       // Mint a new ticket
    fn mint_ticket(
        ref self: Storage,
        ticket_id: u256,
        price: u256,
        quantity: u256,
        expiration: felt252,
        royalties: felt252,
        royalty_recipient: felt252,
    ) {
        // Ensure the ticket does not already exist
        let (existing_metadata) = self.tickets.read(ticket_id);
        assert(existing_metadata.price.low == 0, "Ticket already exists");

        // Store ticket metadata
        self.tickets.write(ticket_id, TicketMetadata(price, quantity, expiration, royalties, royalty_recipient));
        self.owners.write(ticket_id, get_caller_address());

        // Emit event
        TicketMinted(ticket_id, get_caller_address(), get_block_timestamp());
    }


     // Purchase a ticket
    fn purchase_ticket(
        ref self: Storage,
        ticket_id: u256,
    ) {
        // Retrieve ticket metadata
        let (metadata) = self.tickets.read(ticket_id);

        // Ensure the ticket is valid and not expired
        assert(metadata.expiration > get_block_timestamp(), "Ticket expired");
        assert(metadata.quantity.low > 0, "No tickets available");

        // Transfer ownership
        self.owners.write(ticket_id, get_caller_address());

        // Decrease ticket quantity
        self.tickets.write(ticket_id, TicketMetadata(
            metadata.price,
            u256_sub(metadata.quantity, u256_from_felts(1, 0)),
            metadata.expiration,
            metadata.royalties,
            metadata.royalty_recipient
        ));

        // Emit event
        TicketPurchased(ticket_id, get_caller_address(), get_block_timestamp());
    }


     // Validate access to IP content
    fn validate_access(
        ref self: Storage,
        ticket_id: u256,
        user: felt252,
    ) -> felt252 {
        // Check ownership
        let (owner) = self.owners.read(ticket_id);
        assert(owner == user, "Access denied");

        // Emit event
        AccessGranted(ticket_id, user, get_block_timestamp());

        return 1;  // Access granted
    }

     // Resell a ticket
    fn resell_ticket(
        ref self: Storage,
        ticket_id: u256,
        buyer: felt252,
        resale_price: u256,
    ) {
        // Retrieve ticket metadata
        let (metadata) = self.tickets.read(ticket_id);

        // Ensure the seller is the current owner
        let (current_owner) = self.owners.read(ticket_id);
        assert(current_owner == get_caller_address(), "Not the owner");

        // Calculate royalty
        let royalty_amount = u256_div(u256_mul(resale_price, u256_from_felts(metadata.royalties, 0)), u256_from_felts(100, 0));

        // Transfer ownership
        self.owners.write(ticket_id, buyer);

        // Emit event
        TicketResold(ticket_id, get_caller_address(), buyer, get_block_timestamp());
    }

      // Resell a ticket
    fn resell_ticket(
        ref self: Storage,
        ticket_id: u256,
        buyer: felt252,
        resale_price: u256,
    ) {
        // Retrieve ticket metadata
        let (metadata) = self.tickets.read(ticket_id);

        // Ensure the seller is the current owner
        let (current_owner) = self.owners.read(ticket_id);
        assert(current_owner == get_caller_address(), "Not the owner");

        // Calculate royalty
        let royalty_amount = u256_div(u256_mul(resale_price, u256_from_felts(metadata.royalties, 0)), u256_from_felts(100, 0));

        // Transfer ownership
        self.owners.write(ticket_id, buyer);

        // Emit event
        TicketResold(ticket_id, get_caller_address(), buyer, get_block_timestamp());
    }
    }