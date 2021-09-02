version 1.0
import "https://raw.githubusercontent.com/DataBiosphere/analysis_pipeline_WDL/pc-relate/pc-relate/pcrelate.wdl" as pcrelate
import "https://raw.githubusercontent.com/dockstore/checker-WDL-templates/v0.99.1/checker_tasks/filecheck_task.wdl" as verify_file
import "https://raw.githubusercontent.com/dockstore/checker-WDL-templates/v0.99.1/checker_tasks/arraycheck_task.wdl" as verify_array

workflow checker_pcrelate {
	input {
		# parent inputs
		File pca_file
		File gds_file
		File? sample_include_file
		Int? n_pcs
		File? variant_include_file
		Int? variant_block_size
		String? out_prefix
		Int? n_sample_blocks # sb default 1
		File? phenotype_file
		Float? kinship_plot_threshold
		String? group
		Float? sparse_threshold
		Boolean? ibd_probs

		# checker-specific inputs
		File outTruth
		File matrixTruth
		Array[File] plotsTruth
	}

	# Run the workflow to be checked
	call pcrelate.pcrel {
		input:
			pca_file = pca_file,
			gds_file = gds_file,
			sample_include_file = sample_include_file,
			n_pcs = n_pcs,
			variant_include_file = variant_include_file,
			variant_block_size = variant_block_size,
			out_prefix = out_prefix,
			n_sample_blocks = n_sample_blocks,
			phenotype_file = phenotype_file,
			kinship_plot_threshold = kinship_plot_threshold,
			group = group,
			sparse_threshold = sparse_threshold,
			ibd_probs = ibd_probs,
	}

	call verify_file.filecheck as check_output {
		input:
			test = pcrel.pcrelate_output,
			truth = outTruth
	}

	call verify_file.filecheck as check_matrix {
		input:
			test = pcrel.pcrelate_matrix,
			truth = matrixTruth
	}

	# Strictly speaking this only has one truth file, but the CWL considers
	# the plots output to be an array of files
	if (defined(pcrel.pcrelate_plots)) {
		call verify_array.arraycheck_optional as check_plot {
			input:
				test = pcrel.pcrelate_plots,
				truth = plotsTruth,
				fastfail = true
		}
	}

}