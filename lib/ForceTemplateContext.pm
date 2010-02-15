# Copyright (c) 2010 ToI-Planning, All rights reserved.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# $Id$

package ForceTemplateContext;
use strict;

sub _init {
	my $app = MT->instance;
	my $key = 'forcetemplatecontext_init';

	return 1 if $app->request($key);

	require MT::Template;
	no warnings 'redefine';

	my $template_build = \&MT::Template::build;
	*MT::Template::build = sub {
		my $tmpl = shift;
		my $ctx = shift || $tmpl->context;

		local $ctx->{__stash}{blog} = $ctx->{__stash}{blog};
		local $ctx->{__stash}{blog_id} = $ctx->{__stash}{blog_id};

		if ($tmpl->force_blog_context) {
			my $blog = MT::Blog->load($tmpl->blog_id);
			$ctx->{__stash}{blog} = $blog;
			$ctx->{__stash}{blog_id} = $blog->id;
		}

		$template_build->($tmpl, $ctx, @_);
	};

	$app->request($key, 1);
}

sub post_load_template {
	my ($cb, $obj) = @_;

	&_init;
}

sub template_pre_save {
	my ($cb, $obj, $original) = @_;
	my $app = MT->instance;

	if (
		$app->param('force_blog_context_beacon')
		&& (! $app->param('force_blog_context'))
	) {
		$obj->force_blog_context(0);
	}

	1;
}

sub param_edit_template {
	my ($cb, $app, $param, $tmpl) = @_;
	my $plugin = MT->component('ForceTemplateContext');

	return 1 if $param->{'type'} ne 'custom';

	my $blog = MT::Blog->load($param->{'blog_id'})
		or return 1;

	return 1 if $blog->class ne 'website';

	my $placement = $tmpl->getElementById('linked_file');

    my $setting = $tmpl->createElement('app:setting', {
		id => 'force_blog_context',
		label => $plugin->translate('Force template to use blog\'s context'),
		label_class => 'top-label',
	});
    $setting->innerHTML(
		qq(<input type="checkbox" name="force_blog_context" id="force_blog_context" value="1" <mt:If name="force_blog_context"> checked="checked" </mt:If>" mt:watch-change="1" /><input type="hidden" name="force_blog_context_beacon" value="1" />)
	);

    $tmpl->insertAfter($setting, $placement);
}

1;
