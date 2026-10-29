using myservice as service from '../../srv/myservice';
annotate service.Books with @(
    UI.SelectionFields : [
        title,
    ]
);

