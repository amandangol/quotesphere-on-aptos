module 0x34d6b6437bfca564420f3d609e66dc3e4dc625fc1a390efdd55abc1940177819::Quotes {
    use std::signer;
    use std::string::String;
    use aptos_std::table::{Self, Table};
    use aptos_framework::timestamp;
    use std::vector;

    const E_QUOTE_DOES_NOT_EXIST: u64 = 101;
    const E_ALREADY_LIKED: u64 = 103;

    struct Quote has store, drop, copy {
        id: u64,
        content: String,
        author: String,
        created_at: u64,
        shared: bool,
        likes: u64,
        owner: address,
        is_custom: bool,
    }

    struct Quotes has key {
        quote_list: Table<u64, Quote>,
        next_id: u64,
        likes: Table<u64, Table<address, bool>>,
    }

    public entry fun initialize(account: &signer) {
        let account_addr = signer::address_of(account);
        if (!exists<Quotes>(account_addr)) {
            let quotes = Quotes {
                quote_list: table::new(),
                next_id: 0,
                likes: table::new(),
            };
            move_to(account, quotes);
        };
    }

   #[view]
public fun get_all_quotes(address: address): vector<Quote> acquires Quotes {
    assert!(exists<Quotes>(address), 0);
    let quotes = borrow_global<Quotes>(address);
    let result = vector::empty<Quote>();
    let i = 0;
    while (i < quotes.next_id) {
        if (table::contains(&quotes.quote_list, i)) {
            let quote = table::borrow(&quotes.quote_list, i);
            vector::push_back(&mut result, *quote);
        };
        i = i + 1;
    };
    result
}

    public entry fun add_quote(account: &signer, content: String, author: String, is_custom: bool) acquires Quotes {
        let address = signer::address_of(account);
        assert!(exists<Quotes>(address), 0);

        let quotes = borrow_global_mut<Quotes>(address);
        let created_at = timestamp::now_seconds();
        let quote = Quote {
            id: quotes.next_id,
            content,
            author,
            created_at,
            shared: false,
            likes: 0,
            owner: address,
            is_custom,
        };
        table::add(&mut quotes.quote_list, quotes.next_id, quote);
        quotes.next_id = quotes.next_id + 1;
    }

    public entry fun share_quote(account: &signer, quote_id: u64) acquires Quotes {
        let address = signer::address_of(account);
        assert!(exists<Quotes>(address), 0);

        let quotes = borrow_global_mut<Quotes>(address);
        assert!(table::contains(&quotes.quote_list, quote_id), E_QUOTE_DOES_NOT_EXIST);

        let quote = table::borrow_mut(&mut quotes.quote_list, quote_id);
        quote.shared = true;
    }

    public entry fun like_quote(account: &signer, quote_owner: address, quote_id: u64) acquires Quotes {
        let liker_address = signer::address_of(account);
        
        let quotes = borrow_global_mut<Quotes>(quote_owner);

        assert!(table::contains(&quotes.quote_list, quote_id), E_QUOTE_DOES_NOT_EXIST);

        if (!table::contains(&quotes.likes, quote_id)) {
            table::add(&mut quotes.likes, quote_id, table::new());
        };

        let quote_likes = table::borrow_mut(&mut quotes.likes, quote_id);

        assert!(!table::contains(quote_likes, liker_address), E_ALREADY_LIKED);

        table::add(quote_likes, liker_address, true);

        let quote = table::borrow_mut(&mut quotes.quote_list, quote_id);
        quote.likes = quote.likes + 1;
    }

  

     #[view]
public fun search_quotes_by_address(searcher: address, target_address: address): vector<Quote> acquires Quotes {
    assert!(exists<Quotes>(target_address), 0);
    let quotes = borrow_global<Quotes>(target_address);
    let result = vector::empty<Quote>();
    let i = 0;
    while (i < quotes.next_id) {
        if (table::contains(&quotes.quote_list, i)) {
            let quote = table::borrow(&quotes.quote_list, i);
            if (quote.shared || searcher == target_address) {
                vector::push_back(&mut result, *quote);
            };
        };
        i = i + 1;
    };
    result
}

    #[view]
    public fun get_quote_by_id(address: address, quote_id: u64): Quote acquires Quotes {
        assert!(exists<Quotes>(address), 0);
        let quotes = borrow_global<Quotes>(address);
        assert!(table::contains(&quotes.quote_list, quote_id), E_QUOTE_DOES_NOT_EXIST);
        *table::borrow(&quotes.quote_list, quote_id)
    }
}