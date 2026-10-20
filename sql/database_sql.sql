create database Ecommerce
use Ecommerce

create table users(
	user_id int primary key not null auto_increment,
    username varchar(50) unique not null,
    password_hash varchar(255) not null,
    email varchar(100) unique not null,
    phone varchar (20) unique,
    status varchar(20) not null default 'ACTIVE',
	created_at timestamp not null default current_timestamp,
    
    check(
			status in ('ACTIVE','BANNED','INACTIVE')
	)

);

create table customers(
	user_id int primary key ,
    loyalty_points int not null default 0,
    
    constraint fk_customers_user
    foreign key (user_id) references users(user_id),
    
    check( loyalty_points >= 0)
);

create table customer_addresses(
	address_id int primary key not null auto_increment,
    customer_id int not null,
	recipient_name varchar(100) not null,
    recipient_phone varchar(20) not null,
    address_line varchar(255) not null,
    city varchar(100) not null,
    is_default boolean not null default false,
    
    constraint fk_customer_addresses_customers
    foreign key(customer_id) references customers(user_id)
);

create table sellers(
	seller_id int primary key auto_increment,
    user_id int unique not null,
    shop_name varchar(100) unique not null,
    shop_address varchar(255) ,
    rating_avg decimal(3,2) not null default 0.00,
    created_at timestamp not null default current_timestamp,
    
    constraint fk_sellers_user
    foreign key (user_id) references users(user_id),
    
    check( rating_avg >= 0 and rating_avg <= 5)
);

	
create table admins(
	admin_id int primary key auto_increment,
    user_id int unique not null,
    department varchar(100),
    constraint fk_admins_user
    foreign key (user_id) references users(user_id)
);

create table carts(
	cart_id int primary key auto_increment,
    customer_id int unique not null,
    updated_at timestamp not null default current_timestamp on update current_timestamp,
    constraint fk_customers_carts
    foreign key(customer_id) references customers(user_id)
);

create table cart_items (
	cart_id int not null,
    variant_id int not null,
    quantity int not null default 1,
    price decimal(12,2) not null,
    added_at timestamp default current_timestamp,
    
	CONSTRAINT fk_cart_items_carts
        FOREIGN KEY (cart_id) REFERENCES carts (cart_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_cart_items_variants
        FOREIGN KEY (variant_id) REFERENCES product_variants (variant_id),

    CHECK (quantity > 0),
    CHECK (price >= 0),
    
    primary key(cart_id, variant_id)
);

create table categories(
	category_id int primary key auto_increment,
    parent_id int,
    name varchar(100) not null,
    description text,
	
    constraint fk_categories_categories
    foreign key (parent_id) references categories(category_id)
);

create table products(
	product_id int primary key auto_increment,
    seller_id int not null,
    name varchar(150) not null,
    description text,
    status varchar(20) not null default 'ACTIVE',
    created_at timestamp not null default current_timestamp,
    rating_avg   decimal(3,2) not null default 0.00,
	review_count int      not null  default 0,
    
    check(status in('ACTIVE', 'INACTIVE', 'DELETED')),
    check(rating_avg >= 0 AND rating_avg <= 5),
    check(review_count >= 0),
    constraint fk_products_sellers
    foreign key(seller_id) references sellers(seller_id)
);


CREATE TABLE tags (
    tag_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ;



CREATE TABLE  product_tags (
    product_id INT NOT NULL,
    tag_id INT NOT NULL,

    PRIMARY KEY (product_id, tag_id),

    INDEX idx_product_tags_tag_id (tag_id),

    CONSTRAINT fk_product_tags_products
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_product_tags_tags
        FOREIGN KEY (tag_id)
        REFERENCES tags(tag_id)
        ON DELETE CASCADE
);


CREATE TABLE product_variants (
    variant_id   INT PRIMARY KEY AUTO_INCREMENT,
    product_id   INT           NOT NULL,

    sku          VARCHAR(100)  NOT NULL UNIQUE,
    color        VARCHAR(50)   NOT NULL DEFAULT 'N/A',
    size         VARCHAR(50)   NOT NULL DEFAULT 'N/A',
    variant_name VARCHAR(150)  NOT NULL,

    price        DECIMAL(12,2) NOT NULL,
    stock        INT           NOT NULL DEFAULT 0,
    status       VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT fk_product_variants_products
        FOREIGN KEY (product_id) REFERENCES products (product_id),

    CONSTRAINT uq_variants_product_color_size
        UNIQUE (product_id, color, size),

    CHECK (price >= 0),
    CHECK (stock >= 0),
    CHECK (status IN ('ACTIVE', 'INACTIVE', 'DELETED'))
);

CREATE TABLE product_categories (
    product_id  INT NOT NULL,
    category_id INT NOT NULL,

    PRIMARY KEY (product_id, category_id),

    CONSTRAINT fk_product_categories_products
        FOREIGN KEY (product_id) REFERENCES products (product_id),

    CONSTRAINT fk_product_categories_categories
        FOREIGN KEY (category_id) REFERENCES categories (category_id),

    INDEX idx_product_categories_category (category_id)
);

CREATE TABLE orders (
    order_id                INT PRIMARY KEY AUTO_INCREMENT,
    customer_id             INT           NOT NULL,

    order_date              TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status                  VARCHAR(20)   NOT NULL DEFAULT 'PENDING',

    -- Snapshot người nhận tại thời điểm đặt hàng
    recipient_name          VARCHAR(100)  NOT NULL,
    recipient_phone         VARCHAR(20)   NOT NULL,
    shipping_address_snapshot TEXT        NOT NULL,

    -- Tổng kết tài chính
    subtotal                DECIMAL(12,2) NOT NULL,
    shipping_fee            DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_total          DECIMAL(12,2) NOT NULL DEFAULT 0,
    grand_total             DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_orders_customers
        FOREIGN KEY (customer_id) REFERENCES customers (user_id),

    CHECK (status IN ('PENDING', 'PAID', 'PROCESSING', 'PARTIALLY_SHIPPED',
                      'COMPLETED', 'CANCELLED', 'REFUNDED')),
    CHECK (subtotal >= 0),
    CHECK (shipping_fee >= 0),
    CHECK (discount_total >= 0),
    CHECK (grand_total >= 0),
    CHECK (grand_total = subtotal + shipping_fee - discount_total),

    INDEX idx_orders_order_date (order_date),
    INDEX idx_orders_status (status)
);

CREATE TABLE seller_orders (
    seller_order_id INT PRIMARY KEY AUTO_INCREMENT,

    order_id        INT           NOT NULL,
    seller_id       INT           NOT NULL,

    status          VARCHAR(20)   NOT NULL DEFAULT 'PENDING',

    subtotal        DECIMAL(12,2) NOT NULL DEFAULT 0,
    shipping_fee    DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_total  DECIMAL(12,2) NOT NULL DEFAULT 0,
    grand_total     DECIMAL(12,2) NOT NULL DEFAULT 0,

    CONSTRAINT fk_seller_orders_orders
        FOREIGN KEY (order_id) REFERENCES orders (order_id),

    CONSTRAINT fk_seller_orders_sellers
        FOREIGN KEY (seller_id) REFERENCES sellers (seller_id),

    CONSTRAINT uq_seller_orders_order_seller
        UNIQUE (order_id, seller_id),

    CHECK (status IN ('PENDING', 'CONFIRMED', 'PROCESSING',
                      'SHIPPED', 'COMPLETED', 'CANCELLED')),
    CHECK (subtotal >= 0),
    CHECK (shipping_fee >= 0),
    CHECK (discount_total >= 0),
    CHECK (grand_total >= 0),
    CHECK (grand_total = subtotal + shipping_fee - discount_total),

    INDEX idx_seller_orders_seller_status (seller_id, status)
);



CREATE TABLE order_items (
    order_item_id         INT PRIMARY KEY AUTO_INCREMENT,

    seller_order_id       INT           NOT NULL,
    variant_id            INT           NOT NULL,

    -- Snapshot lúc mua, ghi một lần khi tạo đơn và không cập nhật nữa
    product_name_snapshot VARCHAR(150)  NOT NULL,
    variant_name_snapshot VARCHAR(150)  NOT NULL,
    sku_snapshot          VARCHAR(100)  NOT NULL,

    quantity              INT           NOT NULL,
    unit_price            DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_order_items_seller_orders
        FOREIGN KEY (seller_order_id) REFERENCES seller_orders (seller_order_id),

    CONSTRAINT fk_order_items_variants
        FOREIGN KEY (variant_id) REFERENCES product_variants (variant_id),

    CHECK (quantity > 0),
    CHECK (unit_price >= 0)
);


CREATE TABLE promotions (
    promotion_id        INT PRIMARY KEY AUTO_INCREMENT,

    code                VARCHAR(50)   NOT NULL UNIQUE,
    discount_type       VARCHAR(20)   NOT NULL,
    discount_value      DECIMAL(12,2) NOT NULL,

    min_order_value     DECIMAL(12,2) NOT NULL DEFAULT 0,
    max_discount_amount DECIMAL(12,2),
    usage_limit         INT,
    used_count          INT           NOT NULL DEFAULT 0,

    start_date          TIMESTAMP     NOT NULL,
    end_date            TIMESTAMP     NOT NULL,

    CHECK (discount_type IN ('PERCENTAGE', 'FIXED_AMOUNT')),
    CHECK (discount_value > 0),
    CHECK (discount_type = 'FIXED_AMOUNT' OR discount_value <= 100),
    CHECK (min_order_value >= 0),
    CHECK (max_discount_amount >= 0),
    CHECK (usage_limit > 0),
    CHECK (used_count >= 0),
    CHECK (usage_limit IS NULL OR used_count <= usage_limit),
    CHECK (start_date <= end_date)
);

CREATE TABLE promotion_applies (
    order_id        INT           NOT NULL,
    promotion_id    INT           NOT NULL,

    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    used_at         TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (order_id, promotion_id),

    CONSTRAINT fk_promotion_applies_orders
        FOREIGN KEY (order_id) REFERENCES orders (order_id),

    CONSTRAINT fk_promotion_applies_promotions
        FOREIGN KEY (promotion_id) REFERENCES promotions (promotion_id),

    CHECK (discount_amount >= 0)
);


create table payments(
	payment_id int primary key auto_increment,
    order_id int not null,
    
    transaction_ref varchar(100) unique,
    payment_date timestamp,
    payment_method varchar(50) not null,
    amount decimal(12,2) not null,
    status varchar(20) not null,
    
    constraint fk_payments_orders
    foreign key (order_id) references orders(order_id),
    
	INDEX idx_payments_payment_status ( status),
    
    check(payment_method IN ('COD','ZALOPAY', 'VNPAY', 'MOMO', 'CREDIT_CARD')),
    check(status IN ('PENDING', 'SUCCESS', 'FAILED', 'PARTIALLY_REFUNDED', 'REFUNDED')),
    check(amount >= 0)
);

create table shippers(
	shipper_id int primary key auto_increment,
    name varchar(100) not null,
    company varchar(100) not null,
    phone varchar(20),
    website varchar(255),
    email varchar(100)
);


CREATE TABLE shipments (
    shipment_id INT PRIMARY KEY AUTO_INCREMENT,
    seller_order_id INT NOT NULL,
    shipper_id INT NOT NULL,

    tracking_number VARCHAR(100),
    shipped_at TIMESTAMP,
    delivery_at TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'READY_TO_PICK',

    CONSTRAINT fk_shipments_seller_orders
        FOREIGN KEY (seller_order_id)
        REFERENCES seller_orders(seller_order_id),

    CONSTRAINT fk_shipments_shippers
        FOREIGN KEY (shipper_id)
        REFERENCES shippers(shipper_id),

    CONSTRAINT uq_shipments_shipper_tracking
        UNIQUE (shipper_id, tracking_number),

    CHECK (status IN (
        'READY_TO_PICK', 'PICKED_UP', 'IN_TRANSIT',
        'DELIVERED', 'RETURNED', 'CANCELLED'
    )),

    CHECK (
        shipped_at IS NULL
        OR delivery_at IS NULL
        OR delivery_at >= shipped_at
    )
);

CREATE TABLE reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    order_item_id INT NOT NULL UNIQUE,

    rating INT NOT NULL,
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reviews_order_items
        FOREIGN KEY (order_item_id)
        REFERENCES order_items(order_item_id),

    CHECK (rating BETWEEN 1 AND 5)
);









