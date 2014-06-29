requires 'perl', '5.008001';

requires 'Class::AutoloadCAN';
requires 'Data::Structure::Util';
requires 'Data::UUID';
requires 'DBD::Pg';
requires 'IPC::System::Simple';
requires 'Module::Runtime';
requires 'Sub::Install';

requires 'DBIx::Class';
requires 'DBIx::Class::UUIDColumns';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

