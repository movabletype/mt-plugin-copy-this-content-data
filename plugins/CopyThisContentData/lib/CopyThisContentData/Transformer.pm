package CopyThisContentData::Transformer;
use strict;
use warnings;

use JSON ();

use MT;
use MT::ContentStatus;

my %Skip_cols = map { $_ => 1 } qw(
    created_on
    created_by
    modified_on
    modified_by
    authored_on
    author_id
    unpublished_on
    meta
    current_revision
    id
    identifier
    unique_id
);

sub template_param_edit_content_data {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = _get_plugin();

    # Do nothing for new content data.
    return unless $app->param('id') || $app->param('origin');

    # If this request has origin parameter, remove ID from param;
    if ( my $orig_id = $app->param('origin') ) {
        _set_params( $app, $param, $orig_id );

       # Copied content data does not need CopyThisContentData widget. Finish.
        return;
    }

    # Make a new widget
    my $widget = $tmpl->createElement(
        'app:widget',
        {   id    => 'copy-this-content-data-widget',
            label => $plugin->translate('Copy This Content Data'),
        }
    );

    $widget->appendChild(
        $tmpl->createTextNode(
            '<div style="margin-left: auto; margin-right: auto;"><button type="button" id="copy-this-content-data" name="copy-this-content-data" class="action button btn btn-default" style="width: 100%;">'
                . $plugin->translate('Copy This Content Data')
                . '</button></div>'
        )
    );

    # Insert new widget
    $tmpl->insertBefore( $widget,
        $tmpl->getElementById('entry-publishing-widget') );

    # Support Script
    $param->{jq_js_include} ||= '';
    $param->{jq_js_include} .= <<SCRIPT;
    jQuery('#copy-this-content-data').click(function() {
        window.changed = false;
        jQuery('[name=edit-content-type-data-form] > [name=__mode]').val('copy_this_content_data');
        jQuery('[name=edit-content-type-data-form]').submit();
    });
SCRIPT
}

sub _set_params {
    my ( $app, $param, $orig_id ) = @_;
    my $content_data_class = $app->model('content_data');
    my $origin             = $content_data_class->load($orig_id) or return;

    unless ( $app->user->permissions( $origin->blog_id )
        ->can_edit_content_data( $origin, $app->user ) )
    {
        $app->param( 'serialized_data', undef );
        return;
    }

    my $cols = $content_data_class->column_names;
    for my $col (@$cols) {
        next if $Skip_cols{$cols};
        $param->{$col} = $origin->$col;
    }

    # Change status
    $param->{new_object} = 1;
    $param->{status}     = MT::ContentStatus::HOLD();
    $param->{title}
        = _get_plugin()->translate( 'Copy of [_1]', $param->{title} );
    delete $param->{"status_publish"};
    delete $param->{"status_review"};
    delete $param->{"status_spam"};
    delete $param->{"status_future"};
    delete $param->{"status_unpublish"};
    $param->{"status_draft"} = 1;

    # data_label
    my $content_type = $origin->content_type;
    if ( $content_type->data_label ) {
        $param->{can_edit_data_label} = 0;
        if ($orig_id) {
            $param->{data_label}
                = $app->param('data_label') || $origin->label;
        }
        else {
            my $field = MT->model('content_field')->load(
                {   content_type_id => $content_type->id,
                    unique_id       => $content_type->data_label,
                }
                )
                or die MT->translate(
                'Cannot load content field (UniqueID:[_1]).',
                $content_type->data_label );
            $param->{data_label}
                = $app->translate(
                'The value of [_1] is automatically used as a data label.',
                $field->name );
        }
    }
    else {
        $param->{can_edit_data_label} = 1;
        $param->{data_label}          = $app->param('data_label')
            || ( $orig_id ? $origin->label : '' );
    }
}

sub _get_plugin {
    MT->component('CopyThisContentData');
}

1;

