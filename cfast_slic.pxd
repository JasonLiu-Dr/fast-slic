# cython: language_level=3

from libc.stdint cimport uint8_t, uint32_t, uint16_t, int16_t
from libcpp cimport bool

cdef extern from "fast-slic-common.h":
    ctypedef struct Cluster:
        float y
        float x
        float r
        float g
        float b
        float a
        uint16_t number
        uint8_t is_active
        uint32_t num_members

    ctypedef struct Connectivity:
        int num_nodes;
        int *num_neighbors;
        uint32_t **neighbors;


cdef extern from "fast-slic.h":
    Connectivity* fast_slic_get_connectivity(int H, int W, int K, const uint16_t *assignment) nogil
    Connectivity* fast_slic_knn_connectivity(int H, int W, int K, const Cluster* clusters, int num_neighbors) nogil
    void fast_slic_free_connectivity(Connectivity* conn) nogil
    void fast_slic_get_mask_density(int H, int W, int K, const Cluster* clusters, const uint16_t* assignment, const uint8_t *mask, uint8_t *cluster_densities) nogil
    void fast_slic_cluster_density_to_mask(int H, int W, int K, const Cluster *clusters, const uint16_t* assignment, const uint8_t *cluster_densities, uint8_t *result) nogil

cdef extern from "context.h" namespace "fslic":
    cdef cppclass Context:
        int16_t subsample_stride_config
        int num_threads
        float compactness
        float min_size_factor
        bool convert_to_lab
        bool strict_cca

        bool preemptive
        float preemptive_thres

        Context(int H, int W, int K, const uint8_t* image, Cluster *clusters) except +
        void initialize_clusters() nogil
        void initialize_state() nogil
        bool parallelism_supported() nogil
        void iterate(uint16_t *assignment, int max_iter) nogil except +

    cdef cppclass ContextRealDist:
        int16_t subsample_stride_config
        int num_threads
        float compactness
        float min_size_factor
        bool convert_to_lab
        bool strict_cca

        bool preemptive
        float preemptive_thres

        ContextRealDist(int H, int W, int K, const uint8_t* image, Cluster *clusters) except +
        void initialize_clusters() nogil
        void initialize_state() nogil
        bool parallelism_supported() nogil
        void iterate(uint16_t *assignment, int max_iter) nogil except +

    cdef cppclass ContextRealDistL2(ContextRealDist):
        ContextRealDistL2(int H, int W, int K, const uint8_t* image, Cluster *clusters) except +

    cdef cppclass ContextBuilder:
        ContextBuilder()
        ContextBuilder(const char* arch)
        const char** supported_archs()
        bool is_supported_arch()
        const char* get_arch()
        void set_arch(const char* arch)
        Context* build(int H, int W, int K, const uint8_t* image, Cluster *clusters)

cdef extern from "lsc.h" namespace "fslic":
    cdef cppclass ContextLSC(ContextRealDist):
        ContextLSC(int H, int W, int K, const uint8_t* image, Cluster *clusters) except +

    cdef cppclass ContextLSCBuilder:
        ContextLSCBuilder()
        ContextLSCBuilder(const char* arch)
        const char** supported_archs()
        bool is_supported_arch()
        const char* get_arch()
        void set_arch(const char* arch)
        ContextLSC* build(int H, int W, int K, const uint8_t* image, Cluster *clusters)


cdef extern from "cca.h" namespace "cca":
    cdef cppclass ConnectivityEnforcer:
        ConnectivityEnforcer(const uint16_t *labels, int H, int W, int K, int min_threshold, bool strict)
        void execute(uint16_t *out)

cdef class NodeConnectivity:
    cdef Connectivity* _c_connectivity
    cpdef tolist(self)

    @staticmethod
    cdef create(Connectivity* conn)


cdef class SlicModel:
    cdef Cluster* _c_clusters
    cdef readonly int num_components
    cdef public object initialized
    cdef public object arch_name
    cdef public object real_dist
    cdef public object real_dist_type
    cdef public object convert_to_lab
    cdef public object strict_cca
    cdef public object preemptive 
    cdef public float preemptive_thres

    cpdef void initialize(self, const uint8_t [:, :, ::1] image)
    cpdef iterate(self, const uint8_t [:, :, ::1] image, int max_iter, float compactness, float min_size_factor, uint8_t subsample_stride)
    cpdef get_connectivity(self, const int16_t[:,::1] assignments)
    cpdef get_knn_connectivity(self, const int16_t[:,::1] assignments, size_t num_neighbors)
    cpdef get_mask_density(self, const uint8_t[:, ::1] mask, const int16_t[:, ::1] assignments)
    cpdef broadcast_density_to_mask(self, const uint8_t[::1] densities, const int16_t[:, ::1] assignments);
    cdef _get_clusters(self)
    cdef _set_clusters(self, clusters)

cpdef is_supported_arch(arch_name)
cpdef get_supported_archs()

cpdef enforce_connectivity(const int16_t[:,::1] assignments, int min_threshold, bool strict)
