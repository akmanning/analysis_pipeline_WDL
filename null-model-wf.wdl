version 1.0

# [1] null_model_r
task null_model_r {
	input {
		# these are in rough alphabetical order here
		# for sanity's sake, but the inline Python
		# follows the original order of the CWL

		# required files
		String outcome
		File phenotype_file
		String family  # required on SB

		# optional stuff
		File? conditional_variant_file
		Array[String]? covars
		Array[File]? gds_files
		String? group_var
		Boolean? inverse_normal
		Int? n_pcs
		Boolean? norm_bygroup
		String? output_prefix
		File? pca_file
		File? relatedness_matrix_file
		String? rescale_variance
		Boolean? resid_covars
		File? sample_include_file
		
		# runtime attributes
		Int addldisk = 1
		Int cpu = 2
		Int memory = 4
		Int preempt = 3
	}

	# Estimate disk size required
	Int phenotype_size = ceil(size(phenotype_file, "GB"))
	# other files, etc
	Int finalDiskSize = phenotype_size + addldisk

	# Workaround
	# Strictly speaking this is only needed for Array variables
	# But we'll do it for most of 'em for consistency's sake
	Boolean isdefined_conditvar = defined(conditional_variant_file)
	Boolean isdefined_covars = defined(covars)
	Boolean isdefined_gds = defined(gds_files)
	Boolean isdefined_inverse = defined(inverse_normal)
	Boolean isdefined_matrix = defined(relatedness_matrix_file)
	Boolean isdefined_norm = defined(norm_bygroup)
	Boolean isdefined_pca = defined(pca_file)
	Boolean isdefined_resid = defined(resid_covars)
	Boolean isdefined_sample = defined(sample_include_file)
	

	command <<<
		set -eux -o pipefail

		echo "Generating config file"
		python << CODE
		import os
		def split_n_space(py_splitstring):
		# Return [file name with chr name replaced by space, chr name]
		# Ex: test_data_chrX.gdsreturns ["test_data_chr .gds", "X"]
			if(unicode(str(py_splitstring[1][1])).isnumeric()):
				# chr10 and above
				py_thisVcfWithSpace = "".join([
					py_splitstring[0],
					"chr ",
					py_splitstring[1][2:]])
				py_thisChr = py_splitstring[1][0:2]
			else:
				# chr9 and below + chrX
				py_thisVcfWithSpace = "".join([
					py_splitstring[0],
					"chr ",
					py_splitstring[1][1:]])
				py_thisChr = py_splitstring[1][0:1]
			return [py_thisVcfWithSpace, py_thisChr]

		f = open("null_model.config", "a")
		if "~{output_prefix}" != "":
			filename = "~{output_prefix}_null_model"
			f.write('out_prefix "' + filename + '"\n')
			phenotype_filename = "~{output_prefix}_phenotypes.RData"
			f.write('out_phenotype_file "' + phenotype_filename + '"\n')
		
		else:
			f.write('out_prefix "null_model"\n')
			f.write('out_phenotype_file "phenotypes.RData"\n')

		f.write('outcome ~{outcome}\n')
		f.write('phenotype_file "~{phenotype_file}"\n')
		if "~{isdefined_gds}" == "true":
			py_gds_array = ['~{sep="','" gds_files}']
			gds = py_gds_array[0]
			py_splitup = split_n_space(gds)[0]
			chr = split_n_space(gds)[1]
			f.write('gds_file "' + py_splitup + chr + '"\n')
		if "~{isdefined_pca}" == "true":
			f.write('pca_file "~{pca_file}"\n')
		if "~{isdefined_matrix}" == "true":
			f.write('relatedness_matrix_file "~{relatedness_matrix_file}"\n')
		if "~{family}" != "":
			f.write('family ~{family}\n')
		if "~{isdefined_conditvar}" == "true":
			f.write('conditional_variant_file "~{conditional_variant_file}"\n')
		if "~{isdefined_covars}" == "true":
			f.write('covars ""~{sep=" " covars}""\n')
		if "~{group_var}" != "":
			f.write('group_var "~{group_var}"\n')
		if "~{isdefined_inverse}" == "true":
			f.write('inverse_normal ~{inverse_normal}\n')
		if "~{n_pcs}" != "":
			if ~{n_pcs} > 0:
				f.write('n_pcs ~{n_pcs}\n')
		if "~{rescale_variance}" != "":
			f.write('rescale_variance "~{rescale_variance}"\n')
		if "~{isdefined_resid}" == "true":
			f.write('reside_covars ~{resid_covars}\n')
		if "~{isdefined_sample}" == "true":
			f.write('sample_include_file "~{sample_include_file}"\n')
		if "~{isdefined_norm}" == "true":
			f.write('norm_bygroup ~{norm_bygroup}\n')

		f.close()
			
		############
		'''
		CWL now has output inherit inputs metadata

		class: InlineJavascriptRequirement
		expressionLib:
		- |2-

			var setMetadata = function(file, metadata) {
				if (!('metadata' in file))
					file['metadata'] = metadata;
				else {
					for (var key in metadata) {
						file['metadata'][key] = metadata[key];
					}
				}
				return file
			};

			var inheritMetadata = function(o1, o2) {
				var commonMetadata = {};
				if (!Array.isArray(o2)) {
					o2 = [o2]
				}
				for (var i = 0; i < o2.length; i++) {
					var example = o2[i]['metadata'];
					for (var key in example) {
						if (i == 0)
							commonMetadata[key] = example[key];
						else {
							if (!(commonMetadata[key] == example[key])) {
								delete commonMetadata[key]
							}
						}
					}
				}
				if (!Array.isArray(o1)) {
					o1 = setMetadata(o1, commonMetadata)
				} else {
					for (var i = 0; i < o1.length; i++) {
						o1[i] = setMetadata(o1[i], commonMetadata)
					}
				}
				return o1;
			};
		'''
		############
		exit()
		CODE
		
		echo "Calling R script null_model.R"
		Rscript /usr/local/analysis_pipeline/R/null_model.R null_model.config
	>>>
	
	runtime {
		cpu: cpu
		docker: "uwgac/topmed-master:2.10.0"
		disks: "local-disk " + finalDiskSize + " HDD"
		memory: "${memory} GB"
		preemptibles: "${preempt}"
	}
	output {
		File config_file = "null_model.config"  # globbed in CWL?
		File null_model_phenotypes = "*phenotypes.RData"  # should inherit metadata
		Array[File] null_model_files = if output_prefix != "" then "{output_prefix}_null_model*RData" else "*null_model*RData"
		File null_model_params = "*.params"
		# todo: null model output https://github.com/aofarrel/analysis_pipeline_cwl/blob/63e0ef1b4a8d1547cb2967ab8ebef4466292a07b/association/tools/null_model_r.cwl#L347
	}
}


# [2] null_model_report
task null_model_report {
	input {
		# these are in rough alphabetical order here
		# for sanity's sake, but the inline Python
		# follows the original order of the CWL

		# required
		String family
		String outcome
		File phenotype_file

		# optional
		File? conditional_variant_file
		Array[String]? covars
		Array[File]? gds_files
		String? group_var
		Boolean? inverse_normal
		Int? n_pcs
		Boolean? norm_bygroup
		String? output_prefix
		File? pca_file
		File? relatedness_matrix_file
		String? rescale_variance
		Boolean? resid_covars
		File? sample_include_file
		
		# report-specific variable
		Int? n_categories_boxplot

		# runtime attr
		Int addldisk = 1
		Int cpu = 2
		Int memory = 4
		Int preempt = 2
	}
	command <<<
		set -eux -o pipefail

		echo "Generating config file"
		python << CODE
		import os
		f = open("null_model_report.config", "a")
		f.write("family ~{family}\n")
		if "~{isdefined_inverse}" == "true":
			f.write("inverse_normal ~{inverse_normal}\n")
		if "~{output_prefix}" != "":
			f.write('out_prefix "~{output_prefix}"\n')
		else:
			f.write('out_prefix "null_model"\n')
		if "~{isdefined_catbox}" == "true":
			f.write("n_catagories_boxplot ~{n_categories_boxplot}\n")
		f.close

		CODE
		
		echo "Calling null_model_report.R"
		Rscript /usr/local/analysis_pipeline/R/null_model_report.R null_model_report.config
	>>>
	# Estimate disk size required
	Int phenotype_size = ceil(size(phenotype_file, "GB"))
	Int finalDiskSize = 2*phenotype_size + addldisk

	# Workaround
	# Strictly speaking this is only needed for Array variables
	# But we'll do it for most of 'em for consistency's sake
	Boolean isdefined_catbox = defined(n_categories_boxplot)
	Boolean isdefined_conditvar = defined(conditional_variant_file)
	Boolean isdefined_covars = defined(covars)
	Boolean isdefined_gds = defined(gds_files)
	Boolean isdefined_inverse = defined(inverse_normal)
	Boolean isdefined_matrix = defined(relatedness_matrix_file)
	Boolean isdefined_norm = defined(norm_bygroup)
	Boolean isdefined_pca = defined(pca_file)
	Boolean isdefined_resid = defined(resid_covars)
	Boolean isdefined_sample = defined(sample_include_file)
	

	runtime {
		cpu: cpu
		docker: "uwgac/topmed-master:2.10.0"
		disks: "local-disk " + finalDiskSize + " HDD"
		memory: "${memory} GB"
		preemptibles: "${preempt}"
	}
	output {
		File null_model_report_config = "null_model_report.config"  # glob in CWL?
		Array[File] html_reports = glob("*.html")
		Array[File] rmd_files = glob("*.rmd")
	}
}

workflow nullmodel {
	input {

		# These variables are used by all tasks
		# n_categories_boxplot and the runtime
		# attributes are the only task-level ones

		String family
		File phenotype_file
		String outcome

		File? conditional_variant_file
		Array[String]? covars
		Array[File]? gds_files
		String? group_var
		Boolean? inverse_normal
		Int? n_pcs
		Boolean? norm_bygroup
		String? output_prefix
		File? pca_file
		File? relatedness_matrix_file
		String? rescale_variance
		Boolean? resid_covars
		File? sample_include_file
	}
	
	call null_model_r {
		input:
			family = family,
			phenotype_file = phenotype_file,
			outcome = outcome,
			conditional_variant_file = conditional_variant_file,
			covars = covars,
			gds_files = gds_files,
			group_var = group_var,
			inverse_normal = inverse_normal,
			n_pcs = n_pcs,
			norm_bygroup = norm_bygroup,
			output_prefix = output_prefix,
			pca_file = pca_file,
			relatedness_matrix_file = relatedness_matrix_file,
			rescale_variance = rescale_variance,
			resid_covars = resid_covars,
			sample_include_file = sample_include_file
	}

	#call null_model_report {
	#	input:
	#		family = family,
	#		outcome = outcome,
	#		phenotype_file = phenotype_file
	#}

	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}
