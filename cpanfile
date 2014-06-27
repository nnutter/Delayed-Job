requires 'perl', '5.008001';

requires 'Data::UUID';
requires 'DBD::Pg';

requires 'DBIx::Class';
requires 'DBIx::Class::UUIDColumns';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

